//
//  MessageRating.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 12.08.20.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import Foundation

/// Derived from the adapter's `PEPRating`, which in turn is derived from
/// the engine's `PEP_rating`.
enum MessageRating {
    case undefined
    case cannotDecrypt
    case haveNoKey
    case unencrypted
    case unreliable
    case b0rken
    case reliable
    case trusted
    case trustedAndAnonymized
    case fullyAnonymous
    case mistrust
    case underAttack
}
