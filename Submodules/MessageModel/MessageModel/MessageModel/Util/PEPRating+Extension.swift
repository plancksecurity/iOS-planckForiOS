//
//  PEPRating+Extension.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 01.03.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation

import pEpIOSToolbox
import PEPObjCAdapterFramework

extension PEPRating {
    public func pEpColor() -> PEPColor {
        return AdapterWrapper.pEpColor(pEpRating: self)
    }
}

extension PEPRating {
    /**
     - Note: TODO: Strong candidate for getting moved into the app.
     */
    static let neverShowAttachmentsForRatings: [PEPRating] = [.cannotDecrypt,
                                                              .haveNoKey]

    /**
     - Note: TODO: Strong candidate for getting moved into the app.
     */
    func dontShowAttachments() -> Bool {
        return PEPRating.neverShowAttachmentsForRatings.contains(self)
    }
}

extension PEPRating {
    static func fromString(str: String) -> PEPRating {//???: IOS-2325_!
        return PEPSession().rating(from:str)//???: IOS-2325_!
    }

    func asString() -> String {//???: IOS-2325_!
        return PEPSession().string(from: self)//???: IOS-2325_!
    }
}

extension PEPRating {
    /**
     Should message content be updated (apart from the message rating)?
     - Note: TODO: Strong candidate for getting moved into the app.
     */
    func shouldUpdateMessageContent() -> Bool {
        switch self {
        case .cannotDecrypt,
             .haveNoKey,
             .b0rken:
            return false

        case .undefined,
             .unencrypted,
             .unencryptedForSome,
             .unreliable,
             .reliable,
             .trusted,
             .trustedAndAnonymized,
             .fullyAnonymous,
             .mistrust,
             .underAttack:
            return true
        default:
            Log.shared.errorAndCrash(
                "cannot decide isUnderAttack() for %@", self.rawValue)
            return false
        }
    }
}

extension PEPRating {

    /// The `PEPRating`s that indicates a message could not be decrypted.
    /// Use for later decryption attemp, e.g. after syncing keys with another device.
    static let undecryptableRatings: [PEPRating] = [.cannotDecrypt, .haveNoKey]

    /** Does the given pEp rating mean the user is under attack? */
    func isUnderAttack() -> Bool {
        switch self {
        case .undefined,
             .cannotDecrypt,
             .haveNoKey,
             .unencrypted,
             .unencryptedForSome,
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
}
