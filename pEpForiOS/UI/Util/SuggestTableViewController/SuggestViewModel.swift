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
        // These identities MUST be used on `session` only!
        fileprivate let from: Identity?
        fileprivate let to: Identity?
        public let name: String
        public let email: String
        fileprivate let addressBookID: String?

        fileprivate init(sender: Identity?,
                         to: Identity? = nil,
                         recipientName: String,
                         recipientEmail: String,
                         recipientAddressBookID: String? = nil) {
            self.from = sender
            self.to = to
            self.name = recipientName
            self.email = recipientEmail
            self.addressBookID = recipientAddressBookID
        }

        fileprivate init(sender: Identity?, recipient: Identity) {
            self.init(sender: sender,
                      to: recipient,
                      recipientName: recipient.userName ?? "",
                      recipientEmail: recipient.address,
                      recipientAddressBookID: recipient.addressBookID)
        }

        static func rows(forSender sender: Identity, recipients: [Identity]) -> [Row] {
            return recipients.map { Row(sender: sender, recipient: $0) }
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

    public subscript(index: Int) -> Row? {
        if rows.count > index {
            return rows[index]
        }
        return nil
    }

    /// Update the suggestions based of the user input.
    /// - Parameter searchString: The text the user searches.
    public func updateSuggestion(searchString: String) {
        workQueue.cancelAllOperations()

        guard searchString.count >= minNumberSearchStringChars else {
            rows.removeAll()
            informDelegatesModelChanged()
            return
        }

        let identities = Identity.recipientsSuggestions(for: searchString)
        if identities.count > 0 {
            // We found matching Identities in the DB.
            // Show them to the user imediatelly and update the list later when Contacts are
            // fetched too.
            guard let from = from else {
                Log.shared.errorAndCrash("No sender in compose?")
                return
            }
            rows = Row.rows(forSender: from, recipients: identities)
            informDelegatesModelChanged()
        }
        let op = SelfReferencingOperation() { [weak self] (operation) in
            guard let me = self else {
                // self == nil is a valid case here. The view might have been dismissed.
                return
            }
            me.session.performAndWait {
                let contacts = AddressBook.searchContacts(searchterm: searchString)
                me.updateRows(with: identities, contacts: contacts, callingOperation: operation)
            }
            AppSettings.shared.userHasBeenAskedForContactAccessPermissions = true
        }
        workQueue.addOperation(op)
    }
}

// MARK: pEp Rating Icon

extension SuggestViewModel {

    /// Get the pep rating icon.
    /// - Parameters:
    ///   - row: The row that represents the suggestion.
    ///   - completion: The callback where the pep rating icon is returned.
    public func pEpRatingIcon(for row: Row, completion: @escaping (UIImage?)->Void) {
        workQueue.addOperation { [weak self] in
            guard let me = self else {
                //Valid case: view might be dismissed
                return
            }
            guard let from = row.from else {
                Log.shared.errorAndCrash("No From")
                completion(Rating.undefined.pEpColor().statusIconInContactPicture())
                return
            }
            guard let to = row.to else {
                //Valid, might not be a "To" recipient.
                completion(Rating.undefined.pEpColor().statusIconInContactPicture())
                return
            }
            let sessionedFrom = Identity.makeSafe(from, forSession: me.session)
            let sessionedTo = Identity.makeSafe(to, forSession: me.session)
            me.session.performAndWait {
                Rating.outgoingMessageRating(from: sessionedFrom, to: [sessionedTo], cc: [], bcc: []) { (rating) in
                    completion(rating.pEpColor().statusIconInContactPicture())
                }
            }
        }
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
            guard let me = self else {
                // Valid case. We might have been dismissed already.
                return
            }
            let emailsOfIdentities = identities.map { $0.address }
            guard let from = me.from else {
                Log.shared.errorAndCrash("No sender in compose?")
                return
            }
            mergedRows = Row.rows(forSender: from, recipients: identities)

            for contact in contacts {
                let name = contact.givenName + " " + contact.familyName
                var contactRowsToAdd = [Row]()
                for email in contact.emailAddresses {
                    if let idx = emailsOfIdentities.firstIndex(of: email.value as String) {
                        // An Identity fort he contact exists already. Update it and ignore the
                        // contact.
                        let identity = identities[idx]
                        identity.update(userName: name, addressBookID: contact.identifier)
                        me.needsSave = true
                        contactRowsToAdd.removeAll()
                        break
                    } else {
                        // No Identity exists for the contact. Show it.
                        let row = Row(sender: from,
                                      recipientName: name,
                                      recipientEmail: email.value as String,
                                      recipientAddressBookID: contact.identifier)
                        contactRowsToAdd.append(row)
                    }
                }
                mergedRows.append(contentsOf: contactRowsToAdd)
            }
        }
        return mergedRows
    }

    private func informDelegatesModelChanged(callingOperation: SelfReferencingOperation?) {
        DispatchQueue.main.async { [weak self] in
            guard let me = self else {
                // Valid case. We might have been dismissed already.
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
