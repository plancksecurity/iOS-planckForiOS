//
//  CdIdentity+Extensions.swift
//  MessageModel
//
//  Created by Andreas Buff on 14.05.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import CoreData

// MARK: - Find

extension CdIdentity {

    //!!!: Docs re context
    public static func search(address: String,
                              context: NSManagedObjectContext) -> CdIdentity? {
        let predicate = NSPredicate(format: "address like[c] %@", address)
        let cdIdent = CdIdentity.first(predicate: predicate, in: context)
        return cdIdent
    }
}

// MARK: - pEp own user ID

extension CdIdentity {
    @discardableResult
    static func updateOrCreate(withAddress address: String,
                               userID: String? = nil,
                               addressBookID: String? = nil,
                               userName: String? = nil,
                               context: NSManagedObjectContext) -> CdIdentity {
        let createe = CdIdentity.search(address: address, context: context) ?? CdIdentity(context: context)
        createe.updateValues(withAddress: address,
                             userID: userID,
                             addressBookID: addressBookID,
                             userName: userName)
        return createe
    }

    private func updateValues(withAddress address: String,
                              userID: String? = nil,
                              addressBookID: String? = nil,
                              userName: String? = nil) {
        self.address = address.lowercased()
        self.addressBookID = addressBookID

        if self.isMySelf && self.userName == nil && userName != nil {
            // Our user namer never changes
            self.userName = userName
        } else if !self.isMySelf && userName != nil {
            // User name of other people do
            self.userName = userName
        }

        guard self.userID == nil || userID == CdIdentity.pEpOwnUserID else {
            // We must never change an existing userID.
            // It might be known by the engine as unique ID already.
            // There is one exception though: we identified an alrady existing identity is actually
            // mySelf. In this case, we _do_ change the user_id.
            return
        }
        if userID != nil {
            // The Engine has a message with yet unknown (to the app) receipient and created a userID
            self.userID = userID
        } else {
            // The given identity does not offer a userID. Create one.
            // All identities must have a userID.
            self.userID = UUID().uuidString
        }
    }
}
