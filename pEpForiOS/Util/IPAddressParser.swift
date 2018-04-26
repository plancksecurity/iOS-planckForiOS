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
     Checks the given `octets` for being contained in `range`.
     - Returns: The original `octets` if all were an `range`, or nil, if at least one wasn't.
     */
    func check<T>(octets: [T], range: ClosedRange<T>) -> [T]? {
        for oct in octets {
            if !range.contains(oct) {
                return nil
            }
        }
        return octets
    }

    /**
     Checks the given `octets` for being contained in `ranges`.
     - Returns: The original `octets` if all were in their corresponding range (from `ranges`),
     or nil, if at least one wasn't, or if `octets` and `ranges` are not of the same length.
     */
    func check<T>(octets: [T], ranges: [CountableClosedRange<T>]) -> [T]? {
        if octets.count != ranges.count {
            return nil
        }

        for index in 0..<octets.count {
            let element = octets[index]
            let range = ranges[index]
            if !range.contains(element) {
                return nil
            }
        }

        return octets
    }

    /**
     Checks the given `octets` for being contained in all `ranges`.
     Basically calls `check(octets:ranges)` on every element of `ranges`.
     */
    func check<T>(octets: [T], listOfRanges: [[CountableClosedRange<T>]]) -> [T]? {
        for range in listOfRanges {
            let someOctets = check(octets: octets, ranges: range)
            if someOctets == nil {
                return nil
            }
        }
        return octets
    }

    /**
     - Returns: The 4 IPv4 octets, if given a valid IPv4 address, or nil.
     */
    func octetsIPv4(ipAddress: String) -> [Int]? {
        let octets = parseOctets(regex: IPAddressParser.regexIPv4, inputString: ipAddress)
        return check(octets: octets, range: 0...255)
    }
}
