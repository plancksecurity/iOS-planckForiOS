//
//  SuggestViewModel.swift
//  pEp
//
//  Created by Andreas Buff on 01.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel
import pEpIOSToolbox
import Contacts
import PEPObjCAdapterFramework

protocol SuggestViewModelResultDelegate: class {
    /// Will be called whenever the user selects an Identity.
    func suggestViewModelDidSelectContact(identity: Identity)

    func suggestViewModel(_ vm: SuggestViewModel, didToggleVisibilityTo newValue: Bool)
}

protocol SuggestViewModelDelegate: class {
    func suggestViewModelDidResetModel(showResults: Bool)
}

class SuggestViewModel {
    struct Row {
        public let name: String
        public let email: String
        public let addressBookID: String?

        fileprivate init(name: String, email: String, addressBookID: String? = nil) {
            self.name = name
            self.email = email
            self.addressBookID = addressBookID
        }

        fileprivate init(identity: Identity) {
            name = identity.userName ?? ""
            email = identity.address
            addressBookID = identity.addressBookID
        }

        static func rows(fromIdentities identities: [Identity]) -> [Row] {
            return identities.map { Row(identity: $0) }
        }
    }

    weak public var resultDelegate: SuggestViewModelResultDelegate?
    weak public var delegate: SuggestViewModelDelegate?

    private var rows = [Row]()
    private let from: Identity?
    private let minNumberSearchStringChars: UInt
    private let showEmptyList = false
    private var workQueue: OperationQueue = {
        let createe = OperationQueue()
        createe.name = #file + " workQueue"
        createe.maxConcurrentOperationCount = 1
        createe.qualityOfService = QualityOfService.userInteractive
        return createe
    }()

    /// Private session for background usage
    let session = Session()

    /// true if one or more Identities have been update on our private Session
    var needsSave = false

    // MARK: - Life Cycle

    public init(minNumberSearchStringChars: UInt = 1,
                from: Identity? = nil,
                resultDelegate: SuggestViewModelResultDelegate? = nil,
                showEmptyList: Bool = false) {
        self.from = from
        self.minNumberSearchStringChars = minNumberSearchStringChars
        self.resultDelegate = resultDelegate
    }

    deinit {
        if needsSave {
            let ses = session
            session.performAndWait {
                ses.commit()
            }
        }
    }

    // MARK: - API

    public func handleRowSelected(at index: Int) {
        workQueue.cancelAllOperations()
        guard index < rows.count else {
            Log.shared.errorAndCrash("Out of bounds")
            return
        }
        let selectedRow = rows[index]
        let selectedIdentity = Identity(address: selectedRow.email)
        // Potetially update data from Apple Contacts

        if selectedIdentity.update(userName: selectedRow.name,
                                   addressBookID: selectedRow.addressBookID) {
            // Save identity if it has been updated
            Session.main.commit()
        }
        resultDelegate?.suggestViewModelDidSelectContact(identity: selectedIdentity)
    }

    public var numRows: Int {
        return rows.count
    }

    public subscript(index: Int) -> Row {
        return rows[index]
    }

    public func updateSuggestion(searchString: String) {
        workQueue.cancelAllOperations()
        guard searchString.count >= minNumberSearchStringChars else {
            rows.removeAll()
            informDelegatesModelChanged()
            return
        }
        let identities = Identity.recipientsSuggestions(for: searchString)
        let firstOp = updateWithIdentitiesOnly(identities: identities)
        workQueue.addOperation(firstOp)
        let secondOp = updateWithIdentitiesAndContactsOperation(searchString: searchString, identities: identities)
        workQueue.addOperation(secondOp)
    }

    /// Returns the Operation to update rows based only on identities.
    /// - Parameter identities: The identities to update the rows
    /// - Returns: The operation to add to the queue.
    private func updateWithIdentitiesOnly(identities: [Identity]) -> SelfReferencingOperation {
        return SelfReferencingOperation() { [weak self] (operation) in
            guard let me = self else {
                // self == nil is a valid case here. The view might have been dismissed.
                return
            }
                if identities.count > 0 {
                    // We found matching Identities in the DB.
                    // Show them to the user imediatelly and update the list later when Contacts are
                    // fetched too.
                    me.updateRows(with: identities, contacts: [], callingOperation: operation)
                }
        }
    }

    /// Returns the Operation to update rows with the identities and the contacts from the AddressBook.
    /// - Parameters:
    ///   - searchString: The text to filter
    ///   - identities: The identities
    /// - Returns: The operation to add to the queue.
    private func updateWithIdentitiesAndContactsOperation(searchString: String, identities: [Identity]) -> SelfReferencingOperation {
        return SelfReferencingOperation() { [weak self] (operation) in
            guard let me = self else {
                // self == nil is a valid case here. The view might have been dismissed.
                return
            }
                let contacts = AddressBook.searchContacts(searchterm: searchString)
                me.updateRows(with: identities, contacts: contacts, callingOperation: operation)
                AppSettings.shared.userHasBeenAskedForContactAccessPermissions = true
        }
    }

    public func pEpRatingFor(address: String) -> PEPRating {

        guard let from = from else {
            return .undefined
        }
        let to = Identity(address: address)
        let pEpsession = PEPSession()
        let rating = pEpsession.outgoingMessageRating(from: from,
                                                      to: [to],
                                                      cc: [],
                                                      bcc: [])

        return rating
    }
}

// MARK: - Private

extension SuggestViewModel {

    private func updateRows(with identities: [Identity],
                            contacts: [CNContact],
                            callingOperation: SelfReferencingOperation?) {

        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            guard let me = self else {
                // That is a valid case. Compose view is gone before this block started to run.
                return
            }

            me.session.performAndWait {
                var newRows = me.mergeAndIgnoreContactsWeAlreadyHaveAnIdentityFor(identities: identities,
                                                                               contacts: contacts)
                newRows.sort { (row1, row2) -> Bool in
                    row1.name < row2.name
                }
                me.rows = newRows
                // To avoid race conditions, we only trigger changes in UI
                // if there aren't more operations in the queue.
                if me.workQueue.operationCount == 1 {
                    me.informDelegatesModelChanged(callingOperation: callingOperation)
                }
            }
        }
    }

    private func mergeAndIgnoreContactsWeAlreadyHaveAnIdentityFor(identities: [Identity],
                                                                  contacts: [CNContact]) -> [Row] {
        let identities = Identity.makeSafe(identities, forSession: session)
        var mergedRows = [Row]()
        session.performAndWait { [weak self] in
            guard let me = self else {
                Log.shared.lostMySelf()
                return
            }
            let emailsOfIdentities = identities.map { $0.address }
            mergedRows = Row.rows(fromIdentities: identities)
            for contact in contacts {
                let name = contact.givenName + " " + contact.familyName
                var contactRowsToAdd = [Row]()
                for email in contact.emailAddresses {
                    if let idx = emailsOfIdentities.firstIndex(of: email.value as String) {
                        // An Identity fort he contact exists already. Update it and ignore the
                        // contact.
                        let identitity = identities[idx]
                        identitity.update(userName: name, addressBookID: contact.identifier)
                        me.needsSave = true
                        contactRowsToAdd.removeAll()
                        break
                    } else {
                        // No Identity exists for the contact. Show it.
                        let row = Row(name: name,
                                      email: email.value as String,
                                      addressBookID: contact.identifier)
                        contactRowsToAdd.append(row)

                    }
                }
                mergedRows.append(contentsOf: contactRowsToAdd)
            }
        }
        return mergedRows
    }

    private func informDelegatesModelChanged(callingOperation: SelfReferencingOperation?) {
        if let operationWeRunOn = callingOperation {
            guard !operationWeRunOn.isCancelled else {
                // do not bother the UI with outdated data
                return
            }
        }
        informDelegatesModelChanged()
    }

    private func informDelegatesModelChanged() {
        let showResults = rows.count > 0 || showEmptyList
        DispatchQueue.main.async { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            me.delegate?.suggestViewModelDidResetModel(showResults: showResults)
            me.resultDelegate?.suggestViewModel(me, didToggleVisibilityTo: showResults)
        }

    }
}

