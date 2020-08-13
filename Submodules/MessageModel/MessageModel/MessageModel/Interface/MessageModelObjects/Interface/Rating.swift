//
//  Rating.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 12.08.20.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import Foundation

/// Derived from the adapter's `PEPRating`, which in turn is derived from
/// the engine's `PEP_rating`.
public enum Rating {
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

    /// This is a much safer way to get the int value than using rawValue, which is not defined
    /// anyways.
    public func toInt() -> Int {
        return Int(pEpRating().rawValue)
    }

    public func pEpColor() -> Color {
        return Color.from(pEpColor: pEpRating().pEpColor())
    }
}
