//
//  PEP_rating+Extension.swift
//  pEp
//
//  Created by Dirk Zimmermann on 22.05.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

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
    static let retryDecriptionRatings: [PEP_rating] = [PEP_rating_undefined,
                                                       PEP_rating_cannot_decrypt,
                                                       PEP_rating_have_no_key]

    static let neverShowAttachmentsForRatings: [PEP_rating] = [PEP_rating_cannot_decrypt,
                                                               PEP_rating_have_no_key]

    func dontShowAttachments() -> Bool {
        return PEP_rating.neverShowAttachmentsForRatings.contains(self)
    }

    /** Does the given pEp rating mean the user is under attack? */
    func isUnderAttack() -> Bool {
        switch self {
        case PEP_rating_undefined,
             PEP_rating_cannot_decrypt,
             PEP_rating_have_no_key,
             PEP_rating_unencrypted,
             PEP_rating_unencrypted_for_some,
             PEP_rating_unreliable,
             PEP_rating_reliable,
             PEP_rating_trusted,
             PEP_rating_trusted_and_anonymized,
             PEP_rating_fully_anonymous,
             PEP_rating_mistrust,
             PEP_rating_b0rken:
            return false
        case PEP_rating_under_attack:
            return true
        default:
            Log.shared.errorAndCrash(
                component: #function,
                errorString: "cannot decide isUnderAttack() for \(self)")
            return false
        }
    }

    /** Should message content be updated (apart from the message rating)? */
    func shouldUpdateMessageContent() -> Bool {
        switch self {
        case PEP_rating_undefined,
             PEP_rating_cannot_decrypt,
             PEP_rating_have_no_key,
             PEP_rating_b0rken:
            return false

        case PEP_rating_unencrypted,
             PEP_rating_unencrypted_for_some,
             PEP_rating_unreliable,
             PEP_rating_reliable,
             PEP_rating_trusted,
             PEP_rating_trusted_and_anonymized,
             PEP_rating_fully_anonymous,
             PEP_rating_mistrust,
             PEP_rating_under_attack:
            return true
        default:
            Log.shared.errorAndCrash(
                component: #function,
                errorString: "cannot decide isUnderAttack() for \(self)")
            return false
        }
    }

    /** Does this pEp rating mean that decryption should be tried again? */
    func shouldRetryToDecrypt() -> Bool {
        switch self {
        case PEP_rating_undefined,
             PEP_rating_cannot_decrypt,
             PEP_rating_have_no_key,
             PEP_rating_b0rken:
            return true

        case PEP_rating_unencrypted,
             PEP_rating_unencrypted_for_some,
             PEP_rating_unreliable,
             PEP_rating_reliable,
             PEP_rating_trusted,
             PEP_rating_trusted_and_anonymized,
             PEP_rating_fully_anonymous,
             PEP_rating_mistrust,
             PEP_rating_under_attack:
            return false
        default:
            Log.shared.errorAndCrash(
                component: #function,
                errorString: "cannot decide isUnderAttack() for \(self)")
            return false
        }
    }

    /** Were there problems decrypting the message? */
    func isUnDecryptable() -> Bool {
        switch self {
        case PEP_rating_undefined,
             PEP_rating_cannot_decrypt,
             PEP_rating_have_no_key:
            return true

        case PEP_rating_unencrypted,
             PEP_rating_unencrypted_for_some,
             PEP_rating_unreliable,
             PEP_rating_reliable,
             PEP_rating_trusted,
             PEP_rating_trusted_and_anonymized,
             PEP_rating_fully_anonymous,
             PEP_rating_mistrust,
             PEP_rating_b0rken,
             PEP_rating_under_attack:
            return false
        default:
            Log.shared.errorAndCrash(
                component: #function,
                errorString: "cannot decide isUnderAttack() for \(self)")
            return false
        }
    }
}
