//
//  PEP_rating+Extension.swift
//  pEp
//
//  Created by Dirk Zimmermann on 22.05.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation
import pEpIOSToolbox

extension PEP_rating {

    static func fromString(str: String) -> PEP_rating {
        return PEPSession().rating(from:str)
    }

    func asString() -> String {
         return PEPSession().string(from: self)
    }
    
    /**
     The `PEP_rating`s that should trigger another decryption attempt later on.
     */
    static let retryDecriptionRatings: [PEP_rating] = [PEPRatingUndefined,
                                                       PEP_rating_cannot_decrypt,
                                                       PEPRatingHaveNoKey]

    static let neverShowAttachmentsForRatings: [PEP_rating] = [PEP_rating_cannot_decrypt,
                                                               PEPRatingHaveNoKey]

    func dontShowAttachments() -> Bool {
        return PEP_rating.neverShowAttachmentsForRatings.contains(self)
    }

    /** Does the given pEp rating mean the user is under attack? */
    func isUnderAttack() -> Bool {
        switch self {
        case PEPRatingUndefined,
             PEP_rating_cannot_decrypt,
             PEPRatingHaveNoKey,
             PEPRatingUnencrypted,
             PEPRatingUnencrypted_for_some,
             PEP_rating_unreliable,
             PEP_rating_reliable,
             PEP_rating_trusted,
             PEP_rating_trusted_and_anonymized,
             PEP_rating_fully_anonymous,
             PEP_rating_mistrust,
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

    /** Should message content be updated (apart from the message rating)? */
    func shouldUpdateMessageContent() -> Bool {
        switch self {
        case PEPRatingUndefined,
             PEP_rating_cannot_decrypt,
             PEPRatingHaveNoKey,
             PEPRatingBr0ken:
            return false

        case PEPRatingUnencrypted,
             PEPRatingUnencrypted_for_some,
             PEP_rating_unreliable,
             PEP_rating_reliable,
             PEP_rating_trusted,
             PEP_rating_trusted_and_anonymized,
             PEP_rating_fully_anonymous,
             PEP_rating_mistrust,
             PEPRatingUnderAttack:
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
             PEP_rating_cannot_decrypt,
             PEPRatingHaveNoKey,
             PEPRatingBr0ken:
            return true

        case PEPRatingUnencrypted,
             PEPRatingUnencrypted_for_some,
             PEP_rating_unreliable,
             PEP_rating_reliable,
             PEP_rating_trusted,
             PEP_rating_trusted_and_anonymized,
             PEP_rating_fully_anonymous,
             PEP_rating_mistrust,
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
             PEP_rating_cannot_decrypt,
             PEPRatingHaveNoKey:
            return true

        case PEPRatingUnencrypted,
             PEPRatingUnencrypted_for_some,
             PEP_rating_unreliable,
             PEP_rating_reliable,
             PEP_rating_trusted,
             PEP_rating_trusted_and_anonymized,
             PEP_rating_fully_anonymous,
             PEP_rating_mistrust,
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
