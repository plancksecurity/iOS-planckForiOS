//
//  Rating.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 12.08.20.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import Foundation

import PEPObjCAdapter

/// Derived from the adapter's `PEPRating`, which in turn is derived from
/// the engine's `PEP_rating`.
public enum Rating {
    case undefined
    case cannotDecrypt
    case haveNoKey
    case unencrypted
    case mediaKeyEncryption
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

    /// Compares the ratings for this and a given rating.
    /// - Parameter rating: the rating to compare
    /// - returns:  true if the rating represents a less secure communication channel than the given one
    ///             false otherwize.
    public func isLessSecure(than originalRating: Rating) -> Bool {
        if isTrusted() {
            return false
        }
        if self == originalRating {
            return false
        }
        if isReliable() && originalRating.isTrusted() {
           return true
        }
        if !isTrusted() && originalRating.isTrusted() {
            return true
        } else if (!isTrusted() && !isReliable() && originalRating.isReliable()) {
            return true
        } else {
            let isTheOriginalRatingUnreliableOrDangerous = originalRating.isUnreliable() || originalRating.isDangerous()
            let isSelfRatingUndefinedOrDangerous = isUndefined() || isDangerous()
            return isTheOriginalRatingUnreliableOrDangerous && isSelfRatingUndefinedOrDangerous
        }
    }

    /** Does the given planck rating mean the user is under attack? */
    public func isUnderAttack() -> Bool {
        switch self {
        case .undefined,
             .cannotDecrypt,
             .haveNoKey,
             .unencrypted,
             .unreliable,
             .reliable,
             .trusted,
             .mediaKeyEncryption,
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
