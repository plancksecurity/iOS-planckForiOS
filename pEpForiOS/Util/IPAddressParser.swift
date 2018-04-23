//
//  IPAddressParser.swift
//  pEp
//
//  Created by Dirk Zimmermann on 23.04.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

/**
 Various methods for parsing IP addresses from strings.
 */
struct IPAddressParser {
    static let regexIPv4 = try! NSRegularExpression(
        pattern: "^(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})$", options: [])

    /**
     - Returns: The 4 IPv4 octets, if given a valid IPv4 address, or nil.
     */
    func octetsIPv4(ipAddress: String) -> [Int]? {
        IPAddressParser.regexIPv4.enumerateMatches(
            in: ipAddress,
            options: [],
            range: NSRange(location: 0, length: ipAddress.lengthOfBytes(using: .utf8))) {
                result, flags, stop in
                if result?.numberOfRanges == 4 {

                }
        }
        return nil
    }
}
