//
//  String+Email.swift
//  pEp
//
//  Created by Dirk Zimmermann on 20.12.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

/**
 Methods that deal with email detection.
 */
extension String {
    static let gmailRegex = emailProviderDetectionPattern(providerDomainPart: "gmail")
    static let yahooRegex = emailProviderDetectionPattern(providerDomainPart: "yahoo")

    static let probablyValidEmailRegex = try! NSRegularExpression(
        pattern: "^[^@,]+@[^@,]+$", options: .caseInsensitive)

    static func emailProviderDetectionPattern(providerDomainPart: String) -> NSRegularExpression {
        return try! NSRegularExpression(
            // character classes: https://en.wikipedia.org/wiki/Unicode_character_property
            pattern: "[-_[\\p{Ll}\\p{Lu}\\p{Nd}.]]+@\(providerDomainPart)\\.[a-z]+",
            options: [])
    }

    var isGmailAddress: Bool {
        return String.gmailRegex.matchesWhole(string: self.lowercased())
    }

    var isYahooAddress: Bool {
        return String.yahooRegex.matchesWhole(string: self.lowercased())
    }

    /**
     Very rudimentary test whether this String is a valid email.
     - Returns: `true` if the number of matches are exactly 1, `false` otherwise.
     */
    public func isProbablyValidEmail() -> Bool {
        let matches = String.probablyValidEmailRegex.matches(
            in: self, options: [], range: wholeRange())
        return matches.count == 1
    }

    /**
     See https://en.wikipedia.org/wiki/Email_address#Domain
     */
    public func isValidDomainDnsLabel() -> Bool {
        let rangeAlpha: ClosedRange<Character> = "a"..."z"
        let rangeCapitalAlpha: ClosedRange<Character> = "A"..."Z"
        let rangeNumerical: ClosedRange<Character> = "0"..."9"

        var currentIndex = 0

        let theCount = count
        if theCount > 63 {
            return false
        }

        let lastIndex = theCount - 1

        var haveSeenAlpha = false

        for ch in self {
            if ch == "-" {
                if currentIndex == 0 || currentIndex == lastIndex {
                    return false
                }
            } else if rangeAlpha.contains(ch) || rangeCapitalAlpha.contains(ch) {
                haveSeenAlpha = true
            } else if !rangeNumerical.contains(ch) {
                return false
            }

            currentIndex += 1
        }

        return haveSeenAlpha
    }

    /**
     See https://en.wikipedia.org/wiki/Email_address#Domain
     */
    public func isValidDomain() -> Bool {
        let labels = components(separatedBy: ".")
        for label in labels {
            if !label.isValidDomainDnsLabel() {
                return false
            }
        }

        return true
    }

    /**
     Contains a String like e.g. "email1, email2, email3", only probably valid emails?
     - Parameter delimiter: The delimiter that separates the emails.
     - Returns: True if all email parts yield true with `isProbablyValidEmail`.
     */
    public func isProbablyValidEmailListSeparatedBy(_ delimiter: String = ",") -> Bool {
        let emails = self.components(separatedBy: delimiter).map({
            $0.trimmedWhiteSpace()
        })
        for e in emails {
            if e.matches(pattern: "\(delimiter)") || !e.isProbablyValidEmail() {
                return false
            }
        }
        return true
    }
}
