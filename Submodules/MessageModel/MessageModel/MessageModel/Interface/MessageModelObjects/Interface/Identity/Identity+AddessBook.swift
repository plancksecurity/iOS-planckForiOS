//
//  Identity+AddessBook.swift
//  MessageModel
//
//  Created by Andreas Buff on 14.09.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation

/// Interactiion & Conversion Identity <-> Contact

// MARK: - Identity+AddessBook

extension Identity {
    public typealias Updated = Bool

    /// Updates the instance with the given values.
    ///
    /// - note: nil values are ignored.
    ///
    /// - Parameters:
    ///   - userName: display name to update instance with. `nil` values are ignored.
    ///   - addressBookID: Apple Contacts ID. `nil` values are ignored.
    /// - Returns: true if the instance has been updated, false otherwize.
    @discardableResult
    public func update(userName: String? = nil, addressBookID: String? = nil) -> Updated {
        var updated = false
        if let name = userName, name != self.userName {
            cdObject.userName = name
            updated = true
        }
        if let id = addressBookID, id != self.addressBookID {
            cdObject.addressBookID = id
            updated = true
        }
        return updated
    }
}
