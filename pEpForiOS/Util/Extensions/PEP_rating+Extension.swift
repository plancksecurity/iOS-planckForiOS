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
