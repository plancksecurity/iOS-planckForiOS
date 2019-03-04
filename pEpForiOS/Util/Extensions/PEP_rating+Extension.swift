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
        case .Undefined,
             .CannotDecrypt,
             .HaveNoKey,
             .b0rken:
            return true

        case .unencrypted,
             .unencryptedForSome,
             .unreliable,
             .reliable,
             .trusted,
             .trustedAndAnonymized,
             .fullyAnonymous,
             .mistrust,
             .underAttack:
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
        case .Undefined,
             .CannotDecrypt,
             .HaveNoKey:
            return true

        case .unencrypted,
             .unencryptedForSome,
             .unreliable,
             .reliable,
             .trusted,
             .trustedAndAnonymized,
             .fullyAnonymous,
             .mistrust,
             .b0rken,
             .underAttack:
            return false
        default:
            Logger.utilLogger.errorAndCrash(
                "cannot decide isUnderAttack() for %{public}@", self.rawValue)
            return false
        }
    }
}
