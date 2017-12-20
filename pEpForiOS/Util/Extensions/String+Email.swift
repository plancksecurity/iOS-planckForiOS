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
    var isGmailAddress: Bool {
        let gmailRegex = try! NSRegularExpression(
            // character classes: https://en.wikipedia.org/wiki/Unicode_character_property
            pattern: "[-_[\\p{Ll}\\p{Lu}\\p{Nd}]]+@gmail\\.[a-z]+",
            options: [])
        return gmailRegex.matchesWhole(string: self.lowercased())
    }
}
