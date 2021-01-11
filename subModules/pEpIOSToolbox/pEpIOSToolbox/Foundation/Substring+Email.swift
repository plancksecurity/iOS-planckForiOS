//
//  Substring+Email.swift
//  pEp
//
//  Created by Dirk Zimmermann on 24.08.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

/**
 Methods for detecting parts of an email.
 - Note: The String equivalents should defer to these to avoid duplicate code.
 */
extension Substring {
    /**
     See https://en.wikipedia.org/wiki/Email_address#Domain
     */
    public func isValidDomainDnsLabel() -> Bool {
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
            } else if String.rangeLatinLetter.contains(ch) ||
                String.rangeCapitalLatinLetter.contains(ch) {
                haveSeenAlpha = true
            } else if !String.rangeNumerical.contains(ch) {
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
     See https://en.wikipedia.org/wiki/Email_address#Local-part
     */
    public func isValidEmailLocalPart() -> Bool {
        let theCount = count
        if theCount > 64 {
            return false
        }

        let lastIndex = theCount - 1

        var previousCharWasDot = false

        var currentIndex = 0
        for ch in self {
            if ch == "." {
                if previousCharWasDot {
                    return false
                }
                if currentIndex == 0 || currentIndex == lastIndex {
                    return false
                }
                previousCharWasDot = true
            } else {
                previousCharWasDot = false

                let specialChars = Set("!#$%&'*+-/=?^_`{|}~")
                if !specialChars.contains(ch) &&
                    !String.rangeNumerical.contains(ch) &&
                    !String.rangeLatinLetter.contains(ch) &&
                    !String.rangeCapitalLatinLetter.contains(ch) {
                    return false
                }
            }
            currentIndex += 1
        }

        return true
    }
}
