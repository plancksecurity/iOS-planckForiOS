//
//  SuggestViewModel.swift
//  pEp
//
//  Created by Andreas Buff on 01.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel

protocol SuggestViewModelResultDelegate: class {
    /// Will be called whenever the user selects an Identity.
    func suggestViewModelDidSelectContact(identity: Identity)
}

protocol SuggestViewModelDelegate: class {
    func suggestViewModelDidResetModel()
}

class SuggestViewModel {

    struct Row {
        public let name: String
        public let email: String

        fileprivate init(name: String, email: String) {
            self.name = name
            self.email = email
        }

        fileprivate init(identity: Identity) {
            name = identity.userName ?? ""
            email = identity.address
        }
    }

    weak public var resultDelegate: SuggestViewModelResultDelegate?
    weak public var delegate: SuggestViewModelDelegate?

    private var identities = [Identity]()
    private let minNumberSearchStringChars: UInt

    // MARK: - API

    public var isEmpty: Bool {
        return identities.count == 0
    }

    public init(minNumberSearchStringChars: UInt = 3, delegate: SuggestViewModelDelegate? = nil) {
        self.minNumberSearchStringChars = minNumberSearchStringChars
    }

    public func handleRowSelected(at index: Int) {
        guard index < identities.count else {
            Log.shared.errorAndCrash(component: #function, errorString: "Out of bounds")
            return
        }
        resultDelegate?.suggestViewModelDidSelectContact(identity: identities[index])
    }

    public var numRows: Int {
        return identities.count
    }

    public func row(at index: Int) -> Row {
        guard index < identities.count else {
            Log.shared.errorAndCrash(component: #function, errorString: "Index out of bounds")
            return Row(name: "Problem", email: "child")
        }
        let identity = identities[index]

        return Row(identity: identity)
    }

    public func updateSuggestion(searchString: String) {
        identities.removeAll()
        let search = searchString.cleanAttachments
        if (search.count >= minNumberSearchStringChars) {
            identities = Identity.by(snippet: search)
        }
        delegate?.suggestViewModelDidResetModel()
    }
}
