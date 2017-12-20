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
        return Regex.gmailRegex.matchesWhole(string: self.lowercased())
    }
}
