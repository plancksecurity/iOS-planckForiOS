//
//  EmailAddressValidation.swift
//  pEpForiOS
//
//  Created by Xavier Algarra on 24/07/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

public class EmailAddressValidation {

    public init(address: String, separator: String = "@") {
        self.addressComponents = address.components(separatedBy: separator)
        self.generalValidation()
        self.domainValidation()
        self.ipv4Validation()
        self.ipv6Validation()
        result = general && ( domain || ipv4 || ipv6 )
    }

    public var result = false

    private var general = false

    private var domain = false

    private var ipv4 = false

    private var ipv6 = false

    private var addressComponents : [String]?

    private func generalValidation() {
        if let s = addressComponents, s.count > 3 {
            let chars = s[s.endIndex-2].characters
            if chars.last != " " {
                general = true
            }
        }
    }

    private func domainValidation() {
        if let s = addressComponents {
            let domainRegex = "^((?!-)[A-Za-z0-9-]{1,63}(?<!-)\\.)+[A-Za-z]{2,6}$"
            let domainPredicate = NSPredicate(format: "SELF MATCHES %@", domainRegex)
            domain = domainPredicate.evaluate(with: s.last)
        }
    }

    private func ipv4Validation() {
        if let s = addressComponents {
            let ipv4Regex = "^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"
            let ipv4Predicate = NSPredicate(format: "SELF MATCHES %@", ipv4Regex)
            ipv4 = ipv4Predicate.evaluate(with: s.last)
        }
    }

    private func ipv6Validation() {
        if let s = addressComponents?.last {
            let ipv6Parts = s.components(separatedBy: ":")
            var result = true
            ipv6Parts.forEach({ (part) in
                if part == "" {
                    return
                }
                if let value = UInt16(part, radix: 16), value > 0, value < 65535 {
                    return
                }
                result = false
            })
            ipv6 = result
        }
    }
}
