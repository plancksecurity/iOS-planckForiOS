//
//  CdMessagePredicateFactory+KeySync.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 31.07.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation

import PEPObjCTypes_iOS
import PEPObjCAdapter_iOS

/// KeySync specific predicates (message-model internal).
extension CdMessage.PredicateFactory {
    /// Messages with a sent date older than now minus the given time interval.
    /// - Example: `sentDateOlderThan(seconds: 10 * 60)` gives you messages with
    ///    a sent date older than 10 minutes.
    static func sentDateOlderThan(seconds: TimeInterval) -> NSPredicate {
        let dateMax = Date(timeIntervalSinceNow: -seconds)
        return NSPredicate(format: "%K < %@",
                           CdMessage.AttributeName.sent,
                           dateMax as CVarArg)
    }

    /// Messages with a sent date older than we need for auto consume messages.
    /// That means, this predicate takes into account how
    /// long auto consume messages are needed by the app.
    static func sentDateOlderThanNeededForAutoConsume() -> NSPredicate {
        return sentDateOlderThan(seconds: 10 * 60)
    }

    /// - Returns: A predicate that excludes the following type of messages:
    ///    * Messages with a header field of name = "pEp-auto-consume" and value = "yes".
    ///    * Messages with an inReplyTo entry of "".
    ///    * Messages that were marked with `engineHasAskedToSendThis`.
    static func isNotAutoConsumable() -> NSPredicate {
        let noInReplyToTunnel =
            NSPredicate(format: "SUBQUERY(%K, $h, $h.%K = %@).@count = 0",
                        CdMessage.RelationshipName.inReplyTo,
                        CdMessageReference.AttributeName.reference,
                        CdMessage.inReplyToAutoConsume)

        let noAutoconsumeHeader =
            NSPredicate(format: "SUBQUERY(%K, $h, $h.%K = %@ AND $h.%K = %@).@count = 0",
                        CdMessage.RelationshipName.optionalFields,
                        CdHeaderField.AttributeName.name,
                        kPepHeaderAutoConsume,
                        CdHeaderField.AttributeName.value,
                        kPepValueAutoConsumeYes)

        return NSCompoundPredicate(andPredicateWithSubpredicates: [noInReplyToTunnel,
                                                                   noAutoconsumeHeader])
    }

    /// - Returns: A predicate that is the opposite of the one returned by `isNotAutoconsumable`,
    ///    that is, for messages that are not auto consumable.
    static func isAutoConsumable() -> NSPredicate {
        return NSCompoundPredicate(notPredicateWithSubpredicate: isNotAutoConsumable())
    }
}
