//
//  CdMessage+KeySync.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 23.05.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation
import CoreData

extension CdMessage {
    /// The value of the "in-reply-to" header used by pEp to tunnel
    /// an auto-consume tag through mail servers that eliminates
    /// custom headers.
    static let inReplyToAutoConsume = "pEp-auto-consume@pEp.foundation"

    /// Determines whether a message is marked as auto-consumable or not.
    ///
    /// Messages with that flag can be deleted after a certain amount of time,
    /// and should not be shown to the user.
    ///
    /// A corresponding predicate is CdMessage.PredicateFactory.isAutoConsumable().
    ///
    /// - Returns:
    ///    * True if a "pEp-auto-consume" = "yes" header exists.
    ///    * True if an in-reply-to with "pEp-auto-consume@pEp.foundation" exists.
    ///    * False otherwise.
    var isAutoConsumable: Bool {
        for header in (optionalFields?.array as? [CdHeaderField] ?? []) {
            if header.name == kPepHeaderAutoConsume && header.value == kPepValueAutoConsumeYes {
                return true
            }
        }

        for reference in (inReplyTo?.array as? [CdMessageReference] ?? []) {
            if reference.reference == CdMessage.inReplyToAutoConsume {
                return true
            }
        }

        return false
    }
}
