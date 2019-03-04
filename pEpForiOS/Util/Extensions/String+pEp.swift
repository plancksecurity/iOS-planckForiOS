//
//  PEPStatusStrings.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 19.04.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

public struct PEPStatusText {
    let rating: PEPRating
    let title: String
    let explanation: String
    let suggestion: String
}

extension String {
    /**
     All privacy status strings, i18n ready.
     */
    static let pEpRatingTranslations: [PEPRating: PEPStatusText] =
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
         .b0rken:
            PEPStatusText(
                rating:
                .b0rken,
                title:
                NSLocalizedString("Broken",
                                  comment: "Privacy status title"),
                explanation:
                NSLocalizedString("-",
                                  comment: "No privacy status explanation"),
                suggestion: NSLocalizedString("-", comment: "No privacy status suggestion")),
         .mistrust:
            PEPStatusText(
                rating: .mistrust,
                title: NSLocalizedString("Mistrusted",
                                         comment: "Privacy status title"),
                explanation:
                NSLocalizedString("This message has a communication partner that has previously been marked as mistrusted.",
                                  comment: "Privacy status explanation"),
                suggestion:
                NSLocalizedString("Re-establish the connection with your communication partner and try to complete another handshake.",
                                  comment: "Privacy status suggestion")),
         .fullyAnonymous:
            PEPStatusText(
                rating: .fullyAnonymous,
                title:
                NSLocalizedString("Secure & Trusted",
                                  comment: "Privacy status title"),
                explanation:
                NSLocalizedString("This message is secure and trusted.",
                                  comment: "Privacy status explanation"),
                suggestion:
                NSLocalizedString("No action needed!",
                                  comment: "Privacy status suggestion")),
         .trustedAndAnonymized:
            PEPStatusText(
                rating: .trustedAndAnonymized,
                title: NSLocalizedString("Secure & Trusted",
                                         comment: "Privacy status title"),
                explanation: NSLocalizedString("This message is secure and trusted.",
                                               comment: "Privacy status explanation"),
                suggestion: NSLocalizedString("No action needed!",
                                              comment: "Privacy status suggestion")),
         .trusted:
            PEPStatusText(
                rating: .trusted,
                title: NSLocalizedString("Secure & Trusted",
                                         comment: "Privacy status title"),
                explanation: NSLocalizedString("This message is secure and trusted.",
                                               comment: "Privacy status explanation"),
                suggestion: NSLocalizedString("No action needed!",
                                              comment: "Privacy status suggestion")),
         .reliable:
            PEPStatusText(
                rating: .reliable,
                title: NSLocalizedString("Secure",
                                         comment: "Privacy status title"),
                explanation:
                NSLocalizedString("This message is secure but you still need to verify the identity of your communication partner.",
                                  comment: "Privacy status explanation"),
                suggestion:
                NSLocalizedString("Complete a handshake with your communication partner. A handshake is needed only once per partner and will ensure secure and trusted communication.",
                                  comment: "Privacy status suggestion")),
         .unreliable:
            PEPStatusText(
                rating: .unreliable,
                title: NSLocalizedString("Unreliable Security",
                                         comment: "Privacy status title"),
                explanation: NSLocalizedString("This message has unreliable protection",
                                               comment: "Privacy status explanation"),
                suggestion:
                NSLocalizedString("This message has no reliable encryption or no signature. Ask your communication partner to upgrade their encryption solution or install p≡p.",
                                  comment: "Privacy status suggestion")),
         .unencryptedForSome:
            PEPStatusText(
                rating: .unencryptedForSome,
                title: NSLocalizedString("Unsecure for Some",
                                         comment: "Privacy status title"),
                explanation:
                NSLocalizedString("This message is unsecure for some communication partners.",
                                  comment: "Privacy status explanation"),
                suggestion:
                NSLocalizedString("Make sure the privacy status for each communication partner listed is at least secure",
                                  comment: "Privacy status suggestion")),
         .unencrypted:
            PEPStatusText(
                rating: .unencrypted,
                title: NSLocalizedString("Unsecure",
                                         comment: "Privacy status title"),
                explanation: NSLocalizedString("This message is unsecure.",
                                               comment: "Privacy status explanation"),
                suggestion:
                NSLocalizedString("Please ask your communication partner to use an encryption solution or install p≡p.",
                                  comment: "Privacy status suggestion")),
         .HaveNoKey:
            PEPStatusText(
                rating: .HaveNoKey,
                title: NSLocalizedString("Cannot Decrypt",
                                         comment: "Privacy status title"),
                explanation:
                NSLocalizedString("This message cannot be decrypted because the key is not available.",
                                  comment: "Privacy status explanation"),
                suggestion:
                NSLocalizedString("If this message was addressed to you, please inform the sender that you don't have the key.",
                                  comment: "Privacy status suggestion")),
         .CannotDecrypt:
            PEPStatusText(
                rating: .CannotDecrypt,
                title: NSLocalizedString("Cannot Decrypt",
                                         comment: "Privacy status title"),
                explanation: NSLocalizedString("This message cannot be decrypted.",
                                               comment: "Privacy status explanation"),
                suggestion:
                NSLocalizedString("If this message was addressed to you, please inform the sender that you don't have the key.",
                                  comment: "Privacy status suggestion")),
         .Undefined: undefinedPEPMessageRating()]

    public static func undefinedPEPMessageRating() -> PEPStatusText {
        return PEPStatusText(
            rating: .Undefined,
            title: NSLocalizedString("Unknown",
                                     comment: "Privacy status title"),
            explanation:
            NSLocalizedString("This message does not contain enough information to determine if it is secure.",
                              comment: "Privacy status explanation"),
            suggestion: NSLocalizedString("Please add the necessary information.",
                                          comment: "Privacy status suggestion"))
    }

    public static func pEpRatingTranslation(pEpRating: PEPRating?) -> PEPStatusText {
        let defResult = undefinedPEPMessageRating()
        if let rating = pEpRating {
            return pEpRatingTranslations[rating] ??
                pEpRatingTranslations[.Undefined] ?? defResult
        } else {
            return defResult
        }
    }

    public static func pEpTitle(pEpRating: PEPRating?) -> String {
        return pEpRatingTranslation(pEpRating: pEpRating).title
    }

    public static func pEpExplanation(pEpRating: PEPRating?) -> String {
        return pEpRatingTranslation(pEpRating: pEpRating).explanation
    }

    public static func pEpSuggestion(pEpRating: PEPRating?) -> String {
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
