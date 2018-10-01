//
//  SuggestViewModel.swift
//  pEp
//
//  Created by Andreas Buff on 01.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel

protocol SuggestViewModelDelegate: class {
    func suggestViewModelDidSelectContact(identity: Identity)
}

class SuggestViewModel {
    private var identities = [Identity]()
    private let minNumberSearchStringChars: UInt

    // MARK: - API

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

    weak public var delegate: SuggestViewModelDelegate?

    public init(minNumberSearchStringChars: UInt = 3, delegate: SuggestViewModelDelegate? = nil) {
        self.minNumberSearchStringChars = minNumberSearchStringChars
    }

    public func handleRowSelected(at index: Int) {
        guard index < identities.count else {
            Log.shared.errorAndCrash(component: #function, errorString: "Out of bounds")
            return
        }
        delegate?.suggestViewModelDidSelectContact(identity: identities[index])
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

    public func updateSuggestion(_ string: String) {
        //IOS-1369: hide()
        identities.removeAll()

        let search = string.cleanAttachments
        if (search.count < minNumberSearchStringChars) {
            //IOS-1369: hide()
            //IOS-1369: reloadData()
        } else {
            identities = Identity.by(snippet: search)

            if identities.count > 0 {
                //IOS-1369: reloadData()
                //IOS-1369: isHidden = false (show)
                //IOS-1369: reloadData()
            }
        }
    }
}
