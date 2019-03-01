//
//  PEPRating+Extension.swift
//  pEp
//
//  Created by Dirk Zimmermann on 22.05.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation
import pEpIOSToolbox

extension PEPRating {
    /** Does the given pEp rating mean the user is under attack? */
    func isUnderAttack() -> Bool {
        switch self {
        case PEPRatingUndefined,
             PEPRatingCannotDecrypt,
             PEPRatingHaveNoKey,
             PEPRatingUnencrypted,
             PEPRatingUnencrypted_for_some,
             PEPRatingUnReliable,
             PEPRatingReliable,
             PEPRatingTrusted,
             PEPRatingTrustedAndAnonymized,
             PEPRatingFullyAnonymous,
             PEPRatingMistrust,
             PEPRatingBr0ken:
            return false
        case PEPRatingUnderAttack:
            return true
        default:
            Logger.utilLogger.errorAndCrash(
                "cannot decide isUnderAttack() for %{public}@", self.rawValue)
            return false
        }
    }

    /** Does this pEp rating mean that decryption should be tried again? */
    func shouldRetryToDecrypt() -> Bool {
        switch self {
        case PEPRatingUndefined,
             PEPRatingCannotDecrypt,
             PEPRatingHaveNoKey,
             PEPRatingBr0ken:
            return true

        case PEPRatingUnencrypted,
             PEPRatingUnencrypted_for_some,
             PEPRatingUnReliable,
             PEPRatingReliable,
             PEPRatingTrusted,
             PEPRatingTrustedAndAnonymized,
             PEPRatingFullyAnonymous,
             PEPRatingMistrust,
             PEPRatingUnderAttack:
            return false
        default:
            Logger.utilLogger.errorAndCrash(
                "cannot decide isUnderAttack() for %{public}@", self.rawValue)
            return false
        }
    }

    /** Were there problems decrypting the message? */
    func isUnDecryptable() -> Bool {
        switch self {
        case PEPRatingUndefined,
             PEPRatingCannotDecrypt,
             PEPRatingHaveNoKey:
            return true

        case PEPRatingUnencrypted,
             PEPRatingUnencrypted_for_some,
             PEPRatingUnReliable,
             PEPRatingReliable,
             PEPRatingTrusted,
             PEPRatingTrustedAndAnonymized,
             PEPRatingFullyAnonymous,
             PEPRatingMistrust,
             PEPRatingBr0ken,
             PEPRatingUnderAttack:
            return false
        default:
            Logger.utilLogger.errorAndCrash(
                "cannot decide isUnderAttack() for %{public}@", self.rawValue)
            return false
        }
    }
}
