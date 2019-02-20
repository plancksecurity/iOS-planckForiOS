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
    private let showEmptyList = false

    // MARK: - API

    public init(minNumberSearchStringChars: UInt = 3,
                resultDelegate: SuggestViewModelResultDelegate? = nil,
                showEmptyList: Bool = false) {
        self.minNumberSearchStringChars = minNumberSearchStringChars
        self.resultDelegate = resultDelegate
    }

    public func handleRowSelected(at index: Int) {
        guard index < identities.count else {
            Logger.frontendLogger.errorAndCrash("Out of bounds")
            return
        }
        resultDelegate?.suggestViewModelDidSelectContact(identity: identities[index])
    }

    public var numRows: Int {
        return identities.count
    }

    public func row(at index: Int) -> Row {
        guard index < identities.count else {
            Logger.frontendLogger.errorAndCrash("Index out of bounds")
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
        let showResults = identities.count > 0 || showEmptyList
        delegate?.suggestViewModelDidResetModel(showResults: showResults)
        resultDelegate?.suggestViewModel(self, didToggleVisibilityTo: showResults)
    }
}
