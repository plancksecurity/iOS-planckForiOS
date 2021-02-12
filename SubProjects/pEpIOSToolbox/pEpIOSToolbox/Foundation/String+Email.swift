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

    public static func emailProviderDetectionPattern(providerDomainPart: String) -> NSRegularExpression {
        return try! NSRegularExpression(
            // character classes: https://en.wikipedia.org/wiki/Unicode_character_property
            pattern: "[-_[\\p{Ll}\\p{Lu}\\p{Nd}.]]+@\(providerDomainPart)\\.[a-z]+",
            options: [])
    }

    /**
     Very rudimentary test whether this String is a valid email.
     - Returns: `true` if the number of matches are exactly 1, `false` otherwise.
     */
    public func isProbablyValidEmail() -> Bool {
        guard let indexOfAt = firstIndex(of: "@") else {
            return false
        }
        let localPart = self[..<indexOfAt]
        let indexOfDomainPart = index(after: indexOfAt)
        let domainPart = self[indexOfDomainPart...]
        return localPart.isValidEmailLocalPart() && domainPart.isValidDomain()
    }

    /**
     Character range for small latin letters.
     - Note: This is used by a `Substring` extension, but it can probably be found
     easier here.
     */
    public static let rangeLatinLetter: ClosedRange<Character> = "a"..."z"

    /**
     Character range for capital latin letters.
     - Note: This is used by a `Substring` extension, but it can probably be found
     easier here.
     */
    public static let rangeCapitalLatinLetter: ClosedRange<Character> = "A"..."Z"

    /**
     Character range for numerical letters.
     - Note: This is used by a `Substring` extension, but it can probably be found
     easier here.
     */
    public static let rangeNumerical: ClosedRange<Character> = "0"..."9"

    /**
     See https://en.wikipedia.org/wiki/Email_address#Domain and
     the `Substring` method of the same name.
     */
    public func isValidDomainDnsLabel() -> Bool {
        return self[startIndex..<endIndex].isValidDomainDnsLabel()
    }

    /**
     See https://en.wikipedia.org/wiki/Email_address#Domain and
     the `Substring` method of the same name.
     */
    public func isValidDomain() -> Bool {
        return self[startIndex..<endIndex].isValidDomain()
    }

    /**
     See https://en.wikipedia.org/wiki/Email_address#Local-part and
     the `Substring` method of the same name.
     */
    public func isValidEmailLocalPart() -> Bool {
        return self[startIndex..<endIndex].isValidEmailLocalPart()
    }

    /**
     Contains a String like e.g. "email1, email2, email3", only probably valid emails?
     - Parameter delimiter: The delimiter that separates the emails.
     - Returns: True if all email parts yield true with `isProbablyValidEmail`.
     */
    public func isProbablyValidEmailListSeparatedBy(_ delimiter: String = ",") -> Bool {
        let emails = self.components(separatedBy: delimiter).map({
            $0.trimmed()
        })
        for e in emails {
            if e.matches(pattern: "\(delimiter)") || !e.isProbablyValidEmail() {
                return false
            }
        }
        return true
    }
}
