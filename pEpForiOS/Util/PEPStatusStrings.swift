//
//  PEPStatusStrings.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 19.04.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

class PEPStatusStrings {
    /**
     All privacy status strings, i18n ready.
     */
    static let pEpRatingTranslations: [PEP_rating: (String, String, String)] =
        [PEP_rating_under_attack:
            (NSLocalizedString("Under Attack",
                               comment: "Privacy status title"),
             NSLocalizedString("This message is not secure and has been tampered with.",
                               comment: "Privacy status explanation"),
             NSLocalizedString("Separately verify the content of this message with your communication partner.",
                               comment: "Privacy status suggestion")),
         PEP_rating_b0rken:
            (NSLocalizedString("Broken",
                               comment: "Privacy status title"),
             NSLocalizedString("-",
                               comment: "Privacy status explanation"),
             NSLocalizedString("-", comment: "")),
         PEP_rating_mistrust:
            (NSLocalizedString("Mistrusted",
                               comment: "Privacy status title"),
             NSLocalizedString("This message has a communication partner that has previously been marked as mistrusted.",
                               comment: "Privacy status explanation"),
             NSLocalizedString("Re-establish the connection with your communication partner and try to complete another handshake.",
                               comment: "Privacy status suggestion")),
         PEP_rating_fully_anonymous:
            (NSLocalizedString("Secure & Trusted",
                               comment: "Privacy status title"),
             NSLocalizedString("This message is secure and trusted.",
                               comment: "Privacy status explanation"),
             NSLocalizedString("No action needed!",
                               comment: "Privacy status suggestion")),
         PEP_rating_trusted_and_anonymized:
            (NSLocalizedString("Secure & Trusted",
                               comment: "Privacy status title"),
             NSLocalizedString("This message is secure and trusted.",
                               comment: "Privacy status explanation"),
             NSLocalizedString("No action needed!",
                               comment: "Privacy status suggestion")),
         PEP_rating_trusted:
            (NSLocalizedString("Secure & Trusted",
                               comment: "Privacy status title"),
             NSLocalizedString("This message is secure and trusted.",
                               comment: "Privacy status explanation"),
             NSLocalizedString("No action needed!",
                               comment: "Privacy status suggestion")),
         PEP_rating_reliable:
            (NSLocalizedString("Secure",
                               comment: "Privacy status title"),
             NSLocalizedString("This message is secure but you still need to verify the identity of your communication partner.",
                               comment: "Privacy status explanation"),
             NSLocalizedString("Complete a handshake with your communication partner. A handshake is needed only once per partner and will ensure secure and trusted communication.",
                               comment: "Privacy status suggestion")),
         PEP_rating_unreliable:
            (NSLocalizedString("Unreliable Security",
                               comment: "Privacy status title"),
             NSLocalizedString("This message has unreliable protection",
                               comment: "Privacy status explanation"),
             NSLocalizedString("This message has no reliable encryption or no signature. Ask your communication partner to upgrade their encryption solution or install p≡p.",
                               comment: "Privacy status suggestion")),
         PEP_rating_unencrypted_for_some:
            (NSLocalizedString("Unsecure for Some",
                               comment: "Privacy status title"),
             NSLocalizedString("This message is unsecure for some communication partners.",
                               comment: "Privacy status explanation"),
             NSLocalizedString("Make sure the privacy status for each communication partner listed is at least secure",
                               comment: "Privacy status suggestion")),
         PEP_rating_unencrypted:
            (NSLocalizedString("Unsecure",
                               comment: "Privacy status title"),
             NSLocalizedString("This message is unsecure.",
                               comment: "Privacy status explanation"),
             NSLocalizedString("Please ask your communication partner to use an encryption solution or install p≡p.",
                               comment: "Privacy status suggestion")),
         PEP_rating_have_no_key:
            (NSLocalizedString("Cannot Decrypt",
                               comment: "Privacy status title"),
             NSLocalizedString("This message cannot be decrypted because the key is not available.",
                               comment: "Privacy status explanation"),
             NSLocalizedString("If this message was addressed to you, please inform the sender that you don't have the key.",
                               comment: "Privacy status suggestion")),
         PEP_rating_cannot_decrypt:
            (NSLocalizedString("Cannot Decrypt",
                               comment: "Privacy status title"),
             NSLocalizedString("This message cannot be decrypted.",
                               comment: "Privacy status explanation"),
             NSLocalizedString("If this message was addressed to you, please inform the sender that you don't have the key.",
                               comment: "Privacy status suggestion")),
         PEP_rating_undefined:
            (NSLocalizedString("Unknown",
                               comment: "Privacy status title"),
             NSLocalizedString("This message does not contain enough information to determine if it is secure.",
                               comment: "Privacy status explanation"),
             NSLocalizedString("Please add the necessary information.",
                               comment: "Privacy status suggestion"))]

    open static func pEpRatingTranslation(pEpRating: PEP_rating?) -> (String, String, String) {
        let defResult = ("", "", "")
        if let rating = pEpRating {
            return pEpRatingTranslations[rating] ??
                pEpRatingTranslations[PEP_rating_undefined] ?? defResult
        } else {
            return defResult
        }
    }

    open static func pEpTitle(pEpRating: PEP_rating?) -> String {
        return pEpRatingTranslation(pEpRating: pEpRating).0
    }

    open static func pEpExplanation(pEpRating: PEP_rating?) -> String {
        return pEpRatingTranslation(pEpRating: pEpRating).1
    }

    open static func pEpSuggestion(pEpRating: PEP_rating?) -> String {
        return pEpRatingTranslation(pEpRating: pEpRating).2
    }
}
