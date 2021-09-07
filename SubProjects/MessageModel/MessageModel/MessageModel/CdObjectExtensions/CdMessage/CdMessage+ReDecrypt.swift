//
//  CdMessage+ReDecrypt.swift
//  MessageModel
//
//  Created by Andreas Buff on 25.09.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import CoreData
import PEPObjCTypes_iOS
import PEPObjCAdapter_iOS

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

    /// Marks all yet undecryptable message in the DB for retry decrypt. Use after getting new
    /// private key(s).
    /// - Parameters:
    ///   - cdAccount:   account whichs messages should be marked for redecrypt. If nil, all
    ///                     undecryptatble messges in the database are marked.
    ///   - context: context to work on
    static func markAllUndecryptableMessagesForRetryDecrypt(for cdAccount: CdAccount? = nil,
                                                            context: NSManagedObjectContext) {
        var predicate = CdMessage.PredicateFactory.undecryptable()
        if let account = cdAccount {
            let belongsToAccount = CdMessage.PredicateFactory.belongingToAccount(cdAccount: account)
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate,
                                                                            belongsToAccount])
        }
        guard
            let allUndecryptableMsgs = all(predicate: predicate, in: context) as? [CdMessage]
            else {
                // No undecyptable messages exist.
                // Do nothing
                return
        }
        allUndecryptableMsgs.forEach { $0.needsDecrypt = true }
    }
}
