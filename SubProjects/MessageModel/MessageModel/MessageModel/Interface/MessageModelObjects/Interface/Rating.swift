//
//  Rating.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 12.08.20.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import Foundation

import PEPObjCTypes_iOS
import PEPObjCAdapter_iOS

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
}

extension Rating {
    /// The `PEPRating`s that indicates a message could not be decrypted.
    /// Use for later decryption attemp, e.g. after syncing keys with another device.
    private static let undecryptableRatings: [Rating] = [.cannotDecrypt, .haveNoKey]

    /// This is a much safer way to get the int value than using rawValue, which is not defined
    /// anyways.
    public func toInt() -> Int {
        return Int(pEpRating().rawValue)
    }

    public func pEpColor() -> Color {
        return Color(pEpColor: pEpRating().pEpColor())
    }

    /// Compares the pEp colors for this and a given rating.
    /// - Parameter rating: rating to compare pEp color with
    /// - returns:  true if the pEp color represents a less secure communication channel than the given one.
    ///             false otherwize.
    public func hasLessSecurePepColor(than rating: Rating) -> Bool {
        if rating.pEpColor() == .green &&
            self.pEpColor() != .green {
            return true
        } else if rating.pEpColor() == .yellow &&
            (self.pEpColor() != .green && self.pEpColor() != .yellow) {
            return true
        }
        else if rating.pEpColor() == .noColor &&
            (self.pEpColor() != .green && self.pEpColor() != .yellow && self.pEpColor() != .noColor) {
            return true
        }
        return false
    }

    /** Does the given pEp rating mean the user is under attack? */
    public func isUnderAttack() -> Bool {
        switch self {
        case .undefined,
             .cannotDecrypt,
             .haveNoKey,
             .unencrypted,
             .unreliable,
             .reliable,
             .trusted,
             .trustedAndAnonymized,
             .fullyAnonymous,
             .mistrust,
             .b0rken:
            return false
        case .underAttack:
            return true
        }
    }

    /// Whether or not the message could not yet be decrypted
    public func isUnDecryptable() -> Bool {
        return Rating.undecryptableRatings.contains(self)
    }
}

extension Rating {
    static public func outgoingMessageRating(from: Identity,
                                             to: [Identity],
                                             cc: [Identity],
                                             bcc: [Identity],
                                             completion: @escaping (Rating) -> Void) {
        PEPSession().outgoingMessageRating(from: from,
                                           to: to,
                                           cc: cc,
                                           bcc: bcc) { pEpRating in
                                            completion(Rating(pEpRating: pEpRating))
        }
    }
}
