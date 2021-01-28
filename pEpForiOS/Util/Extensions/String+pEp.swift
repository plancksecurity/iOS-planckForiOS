//
//  PEPStatusStrings.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 19.04.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel

public struct PEPStatusText {
    let rating: Rating
    let title: String
    let explanation: String
    let suggestion: String
}

extension String {
    /// Struct that provides the texts to the trust management view according to the colors.
    private struct TrustManagementText {
        static let red = PEPStatusText(rating: .mistrust,
                                       title: NSLocalizedString("Mistrusted", comment: "Privacy status title"),
                                       explanation: NSLocalizedString("This contact is mistrusted. If you rejected the Trustwords accidentally, you could reset the p≡p data.", comment: "Privacy status title"),
                                       suggestion: "")
        static let yellow = PEPStatusText(rating: .reliable,
                                          title: NSLocalizedString("Secure", comment: "Privacy status title"),
                                          explanation: NSLocalizedString("In order to make the communication with this communication partner Secure & Trusted, you will have to compare the Trustwords below with this communication partner and ensure they match yours.", comment: "Privacy status explanation"),
                                          suggestion: "")
        static let green = PEPStatusText(rating: .trusted,
                                         title: NSLocalizedString("Secure & Trusted", comment: "Privacy status title"),
                                         explanation: NSLocalizedString("This contact is completely trusted. All communication will be the maximum level of privacy.", comment: "Privacy status explanation"),
                                         suggestion: "")
        static let noColor = PEPStatusText(rating: .undefined,
                                         title: "",
                                         explanation: "",
                                         suggestion: "")
    }

    /**
     All privacy status strings for the trust management.
     */
    private static let trustIdentityTranslation: [Rating: PEPStatusText] =
        [.underAttack: TrustManagementText.red,
         .b0rken: TrustManagementText.red,
         .mistrust: TrustManagementText.red,
         .reliable: TrustManagementText.yellow,
         .unencrypted: TrustManagementText.noColor,
         .haveNoKey: TrustManagementText.noColor,
         .cannotDecrypt: TrustManagementText.noColor,
         .unreliable: TrustManagementText.noColor,
         .fullyAnonymous: TrustManagementText.green,
         .trustedAndAnonymized: TrustManagementText.green,
         .trusted: TrustManagementText.green,
         .undefined: undefinedPEPMessageRating()]

    /**
     All privacy status strings, i18n ready.
     */
    private static let pEpRatingTranslations: [Rating: PEPStatusText] =
        [.underAttack:
            PEPStatusText(
                rating: .underAttack,
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
         .haveNoKey:
            PEPStatusText(
                rating: .haveNoKey,
                title: NSLocalizedString("Cannot Decrypt",
                                         comment: "Privacy status title"),
                explanation:
                NSLocalizedString("This message cannot be decrypted because the key is not available.",
                                  comment: "Privacy status explanation"),
                suggestion:
                NSLocalizedString("If this message was addressed to you, please inform the sender that you don't have the key.",
                                  comment: "Privacy status suggestion")),
         .cannotDecrypt:
            PEPStatusText(
                rating: .cannotDecrypt,
                title: NSLocalizedString("Cannot Decrypt",
                                         comment: "Privacy status title"),
                explanation: NSLocalizedString("This message cannot be decrypted.",
                                               comment: "Privacy status explanation"),
                suggestion:
                NSLocalizedString("If this message was addressed to you, please inform the sender that you don't have the key.",
                                  comment: "Privacy status suggestion")),
         .undefined: undefinedPEPMessageRating()]

    private static func undefinedPEPMessageRating() -> PEPStatusText {
        return PEPStatusText(
            rating: .undefined,
            title: NSLocalizedString("Unknown",
                                     comment: "Privacy status title"),
            explanation:
            NSLocalizedString("This message does not contain enough information to determine if it is secure.",
                              comment: "Privacy status explanation"),
            suggestion: NSLocalizedString("Please add the necessary information.",
                                          comment: "Privacy status suggestion"))
    }

    public static func pEpRatingTranslation(pEpRating: Rating?) -> PEPStatusText {
        let defResult = undefinedPEPMessageRating()
        if let rating = pEpRating {
            return pEpRatingTranslations[rating] ??
                pEpRatingTranslations[.undefined] ?? defResult
        } else {
            return defResult
        }
    }
    
    
    public static func trustIdentityTranslation(pEpRating: Rating?) -> PEPStatusText {
        let defaultRestult = undefinedPEPTrustIdentityRating()
        if let rating = pEpRating {
            return trustIdentityTranslation[rating] ??
                trustIdentityTranslation[.undefined] ?? defaultRestult
        } else {
            return defaultRestult
        }
    }

    /// Default Status Text, for undefined identity's pEpRating.
    private static func undefinedPEPTrustIdentityRating() -> PEPStatusText {
        let explanation = NSLocalizedString("Unknown.", comment: "Privacy status explanation")
        let title = NSLocalizedString("Unknown", comment: "Privacy status title")
        let suggestion = NSLocalizedString("Unknown.", comment: "Privacy status suggestion")
        return PEPStatusText(
            rating: .undefined,
            title: title,
            explanation: explanation,
            suggestion: suggestion)
    }
}
