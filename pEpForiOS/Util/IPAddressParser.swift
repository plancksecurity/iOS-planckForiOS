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
     Assumes that the `regex` parses a sequence of numbers (and only numbers),
     and returns as an array.
     - Return: The octets parsed. The result might be empty.
     - Note: Since a regex is involved, the `inputString` is cast to a `NSString`.
     The first match is ignored, as this is usually the whole string.
     */
    func parseOctets(regex: NSRegularExpression, inputString: String) -> [Int] {
        var octets = [Int]()
        let nsString = inputString as NSString
        regex.enumerateMatches(
            in: inputString,
            options: [],
            range: NSRange(location: 0, length: nsString.length)) {
                result, flags, stop in
                if let theResult = result {
                    for i in 1..<theResult.numberOfRanges {
                        let range = theResult.range(at: i)
                        let string = nsString.substring(with: range)
                        if let num = Int(string) {
                            octets.append(num)
                        }
                    }
                }
        }
        return octets
    }

    /**
     - Returns: The 4 IPv4 octets, if given a valid IPv4 address, or nil.
     */
    func octetsIPv4(ipAddress: String) -> [Int] {
        return parseOctets(regex: IPAddressParser.regexIPv4, inputString: ipAddress)
    }
}
