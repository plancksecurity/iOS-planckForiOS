//
//  CdMessage+ReDecrypt.swift
//  MessageModel
//
//  Created by Andreas Buff on 25.09.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import CoreData
import PEPObjCAdapterFramework

// MARK: - CdMessage+ReDecrypt

extension CdMessage {

    /// Marks the message to redecrypt if it is yet undecryptable.
    /// - returns: Whether or not the message has been marked for redecryption
    @discardableResult
    func markForRetryDecryptIfUndecryptable() -> Bool {
        var hasBeenMarked = false
        guard
            let rating = PEPRating(rawValue: Int32(self.pEpRating)),
            rating.isUnDecryptable()
            else {
                // Nothing to do. Message is decrypted already
                return hasBeenMarked
        }
        if !needsDecrypt {
            needsDecrypt = true
            hasBeenMarked = true
        }
        return hasBeenMarked
    }

    static func markAllUndecryptableMessagesForRetryDecrypt(context: NSManagedObjectContext) {
        let pUndecryptable = CdMessage.PredicateFactory.undecryptable()
        guard let allUndecryptableMsgs = all(predicate: pUndecryptable, in: context) as? [CdMessage] else {
            // No undecyptable messages exist.
            // Do nothing
            return
        }
        allUndecryptableMsgs.forEach { $0.needsDecrypt = true }
    }
}
