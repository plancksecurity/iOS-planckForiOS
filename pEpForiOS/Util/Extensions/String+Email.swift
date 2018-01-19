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
}
