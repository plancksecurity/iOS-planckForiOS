//
//  PEPStatusStrings.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 19.04.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

public struct PEPStatusText {
    let rating: PEP_rating
    let title: String
    let explanation: String
    let suggestion: String
}

extension String {
    /**
     All privacy status strings, i18n ready.
     */
    static let pEpRatingTranslations: [PEP_rating: PEPStatusText] =
        [PEPRatingUnderAttack:
            PEPStatusText(
                rating: PEPRatingUnderAttack,
                title: NSLocalizedString("Under Attack",
                                         comment: "Privacy status title"),
                explanation:
                NSLocalizedString("This message is not secure and has been tampered with.",
                                  comment: "Privacy status explanation"),
                suggestion:
                NSLocalizedString("Separately verify the content of this message with your communication partner.",
                                  comment: "Privacy status suggestion")),
         PEP_rating_b0rken:
            PEPStatusText(
                rating:
                PEP_rating_b0rken,
                title:
                NSLocalizedString("Broken",
                                  comment: "Privacy status title"),
                explanation:
                NSLocalizedString("-",
                                  comment: "No privacy status explanation"),
                suggestion: NSLocalizedString("-", comment: "No privacy status suggestion")),
         PEP_rating_mistrust:
            PEPStatusText(
                rating: PEP_rating_mistrust,
                title: NSLocalizedString("Mistrusted",
                                         comment: "Privacy status title"),
                explanation:
                NSLocalizedString("This message has a communication partner that has previously been marked as mistrusted.",
                                  comment: "Privacy status explanation"),
                suggestion:
                NSLocalizedString("Re-establish the connection with your communication partner and try to complete another handshake.",
                                  comment: "Privacy status suggestion")),
         PEP_rating_fully_anonymous:
            PEPStatusText(
                rating: PEP_rating_fully_anonymous,
                title:
                NSLocalizedString("Secure & Trusted",
                                  comment: "Privacy status title"),
                explanation:
                NSLocalizedString("This message is secure and trusted.",
                                  comment: "Privacy status explanation"),
                suggestion:
                NSLocalizedString("No action needed!",
                                  comment: "Privacy status suggestion")),
         PEP_rating_trusted_and_anonymized:
            PEPStatusText(
                rating: PEP_rating_trusted_and_anonymized,
                title: NSLocalizedString("Secure & Trusted",
                                         comment: "Privacy status title"),
                explanation: NSLocalizedString("This message is secure and trusted.",
                                               comment: "Privacy status explanation"),
                suggestion: NSLocalizedString("No action needed!",
                                              comment: "Privacy status suggestion")),
         PEP_rating_trusted:
            PEPStatusText(
                rating: PEP_rating_trusted,
                title: NSLocalizedString("Secure & Trusted",
                                         comment: "Privacy status title"),
                explanation: NSLocalizedString("This message is secure and trusted.",
                                               comment: "Privacy status explanation"),
                suggestion: NSLocalizedString("No action needed!",
                                              comment: "Privacy status suggestion")),
         PEP_rating_reliable:
            PEPStatusText(
                rating: PEP_rating_reliable,
                title: NSLocalizedString("Secure",
                                         comment: "Privacy status title"),
                explanation:
                NSLocalizedString("This message is secure but you still need to verify the identity of your communication partner.",
                                  comment: "Privacy status explanation"),
                suggestion:
                NSLocalizedString("Complete a handshake with your communication partner. A handshake is needed only once per partner and will ensure secure and trusted communication.",
                                  comment: "Privacy status suggestion")),
         PEP_rating_unreliable:
            PEPStatusText(
                rating: PEP_rating_unreliable,
                title: NSLocalizedString("Unreliable Security",
                                         comment: "Privacy status title"),
                explanation: NSLocalizedString("This message has unreliable protection",
                                               comment: "Privacy status explanation"),
                suggestion:
                NSLocalizedString("This message has no reliable encryption or no signature. Ask your communication partner to upgrade their encryption solution or install p≡p.",
                                  comment: "Privacy status suggestion")),
         PEPRatingUnencrypted_for_some:
            PEPStatusText(
                rating: PEPRatingUnencrypted_for_some,
                title: NSLocalizedString("Unsecure for Some",
                                         comment: "Privacy status title"),
                explanation:
                NSLocalizedString("This message is unsecure for some communication partners.",
                                  comment: "Privacy status explanation"),
                suggestion:
                NSLocalizedString("Make sure the privacy status for each communication partner listed is at least secure",
                                  comment: "Privacy status suggestion")),
         PEPRatingUnencrypted:
            PEPStatusText(
                rating: PEPRatingUnencrypted,
                title: NSLocalizedString("Unsecure",
                                         comment: "Privacy status title"),
                explanation: NSLocalizedString("This message is unsecure.",
                                               comment: "Privacy status explanation"),
                suggestion:
                NSLocalizedString("Please ask your communication partner to use an encryption solution or install p≡p.",
                                  comment: "Privacy status suggestion")),
         PEPRatingHaveNoKey:
            PEPStatusText(
                rating: PEPRatingHaveNoKey,
                title: NSLocalizedString("Cannot Decrypt",
                                         comment: "Privacy status title"),
                explanation:
                NSLocalizedString("This message cannot be decrypted because the key is not available.",
                                  comment: "Privacy status explanation"),
                suggestion:
                NSLocalizedString("If this message was addressed to you, please inform the sender that you don't have the key.",
                                  comment: "Privacy status suggestion")),
         PEP_rating_cannot_decrypt:
            PEPStatusText(
                rating: PEP_rating_cannot_decrypt,
                title: NSLocalizedString("Cannot Decrypt",
                                         comment: "Privacy status title"),
                explanation: NSLocalizedString("This message cannot be decrypted.",
                                               comment: "Privacy status explanation"),
                suggestion:
                NSLocalizedString("If this message was addressed to you, please inform the sender that you don't have the key.",
                                  comment: "Privacy status suggestion")),
         PEPRatingUndefined: undefinedPEPMessageRating()]

    public static func undefinedPEPMessageRating() -> PEPStatusText {
        return PEPStatusText(
            rating: PEPRatingUndefined,
            title: NSLocalizedString("Unknown",
                                     comment: "Privacy status title"),
            explanation:
            NSLocalizedString("This message does not contain enough information to determine if it is secure.",
                              comment: "Privacy status explanation"),
            suggestion: NSLocalizedString("Please add the necessary information.",
                                          comment: "Privacy status suggestion"))
    }

    public static func pEpRatingTranslation(pEpRating: PEP_rating?) -> PEPStatusText {
        let defResult = undefinedPEPMessageRating()
        if let rating = pEpRating {
            return pEpRatingTranslations[rating] ??
                pEpRatingTranslations[PEPRatingUndefined] ?? defResult
        } else {
            return defResult
        }
    }

    public static func pEpTitle(pEpRating: PEP_rating?) -> String {
        return pEpRatingTranslation(pEpRating: pEpRating).title
    }

    public static func pEpExplanation(pEpRating: PEP_rating?) -> String {
        return pEpRatingTranslation(pEpRating: pEpRating).explanation
    }

    public static func pEpSuggestion(pEpRating: PEP_rating?) -> String {
        return pEpRatingTranslation(pEpRating: pEpRating).suggestion
    }

    /**
     Returns: Interprets itself as a fingerprint and formats it as such.
     */
    public func prettyFingerPrint() -> String {
        let upper = uppercased()
        var totalCount = 0
        var packCount = 0
        var currentPack = ""
        var result = ""
        for character in upper {
            if totalCount != 0 && totalCount % 4 == 0 {
                if packCount == 5 {
                    result += "  "
                } else if packCount > 0 {
                    result += " "
                }
                result += currentPack
                packCount += 1
                currentPack = ""
            }
            currentPack.append(character)
            totalCount += 1
        }
        if !currentPack.isEmpty {
            result += " \(currentPack)"
        }
        return result
    }

    static let pgpMessageTextRegex = try! NSRegularExpression(
        pattern: "^(\\s)*-----BEGIN PGP MESSAGE-----",
        options: [])

    /**
     Does this string start with "-----BEGIN PGP MESSAGE-----",
     apart from any leading spaces?
     */
    public func startsWithBeginPgpMessage() -> Bool {
        if let _ = String.pgpMessageTextRegex.firstMatch(
            in: self, options: [],
            range: wholeRange()) {
            return true
        }
        return false
    }
}
