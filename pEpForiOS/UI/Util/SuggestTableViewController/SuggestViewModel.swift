//
//  SuggestViewModel.swift
//  pEp
//
//  Created by Andreas Buff on 01.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel
import pEpIOSToolbox

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

        //BUFF: inti for contact


    }

    weak public var resultDelegate: SuggestViewModelResultDelegate?
    weak public var delegate: SuggestViewModelDelegate?

    private var rows = [Row]()
    private let minNumberSearchStringChars: UInt
    private let showEmptyList = false

    // MARK: - API

    public init(minNumberSearchStringChars: UInt = 3,
                resultDelegate: SuggestViewModelResultDelegate? = nil,
                showEmptyList: Bool = false) {
        self.minNumberSearchStringChars = minNumberSearchStringChars
        self.resultDelegate = resultDelegate
    }

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
        rows.removeAll()
        let search = searchString
        if (search.count >= minNumberSearchStringChars) {
            let identities = Identity.by(snippet: search)
            rows = identities.map { Row(identity: $0) }
        }
        let showResults = rows.count > 0 || showEmptyList
        delegate?.suggestViewModelDidResetModel(showResults: showResults)
        resultDelegate?.suggestViewModel(self, didToggleVisibilityTo: showResults)
    }
}
