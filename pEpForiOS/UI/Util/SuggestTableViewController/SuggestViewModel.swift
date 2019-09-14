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
        let addressBookID: String?

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

    public init(minNumberSearchStringChars: UInt = 3,
                resultDelegate: SuggestViewModelResultDelegate? = nil,
                showEmptyList: Bool = false) {
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
        let identities = Identity.by(snippet: searchString)
        if identities.count > 0 {
            // We found matching Identities in the DB.
            // Show them to the user imediatelly and update the list later when Contacts are
            // fetched too.
            rows = Row.rows(fromIdentities: identities)
            informDelegatesModelChanged()
        }
        let op = SelfReferencingOperation() { [weak self] (operation) in
            guard let me = self else {
                // self == nil is a valid case here. The view might have been dismissed.
                return
            }
            let contacts = AddressBook.shared.searchContacts(searchterm: searchString)
            me.updateRows(with: identities, contacts: contacts, callingOperation: operation)
        }
        workQueue.addOperation(op)
    }
}

// MARK: - Private

extension SuggestViewModel {

    private func updateRows(with identities: [Identity],
                            contacts: [CNContact],
                            callingOperation: SelfReferencingOperation?) {
        var newRows = mergeAndIgnoreContactsWeAlreadyHaveAnIdentityFor(identities: identities,
                                                                       contacts: contacts)
        newRows.sort { (row1, row2) -> Bool in
            row1.name < row2.name
        }
        rows = newRows
        informDelegatesModelChanged(callingOperation: callingOperation)
    }

    private func mergeAndIgnoreContactsWeAlreadyHaveAnIdentityFor(identities: [Identity],
                                                                  contacts: [CNContact]) -> [Row] {
        let identities = Identity.makeSafe(identities, forSession: session)
        var mergedRows = [Row]()
        session.performAndWait { [weak self] in
            let emailsOfIdentities = identities.map { $0.address }
            mergedRows = Row.rows(fromIdentities: identities)
            for contact in contacts {
                let name = contact.givenName + " " + contact.familyName
                for email in contact.emailAddresses {
                    if let idx = emailsOfIdentities.firstIndex(of: email.value as String) {
                        // An Identity fort he contact exists already. Update it and ignore the
                        // contact.
                        let identitity = identities[idx]
                        identitity.update(userName: name, addressBookID: contact.identifier)
                        self?.needsSave = true
                    } else {
                        // No Identity exists for the contact. Show it.
                        let row = Row(name: name,
                                      email: email.value as String,
                                      addressBookID: contact.identifier)
                        mergedRows.append(row)
                    }
                }
            }
        }
        return mergedRows
    }

    private func informDelegatesModelChanged(callingOperation: SelfReferencingOperation?) {
        DispatchQueue.main.async { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            if let operationWeRunOn = callingOperation {
                guard !operationWeRunOn.isCancelled else {
                    // do not bother the UI with outdated data
                    return
                }
            }
            me.informDelegatesModelChanged()
        }
    }

    private func informDelegatesModelChanged() {
        let showResults = rows.count > 0 || showEmptyList

        delegate?.suggestViewModelDidResetModel(showResults: showResults)
        resultDelegate?.suggestViewModel(self, didToggleVisibilityTo: showResults)
    }
}
