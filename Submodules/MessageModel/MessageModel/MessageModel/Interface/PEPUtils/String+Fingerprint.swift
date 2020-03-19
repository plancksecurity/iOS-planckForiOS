//
//  String+Fingerprint.swift
//  MessageModel
//
//  Created by Martin Brude on 11/02/2020.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import Foundation

extension String {

    /// Interprets itself as a fingerprint and formats it as such.
    /// Example usage: somePEPIdentity.fingerPrint?.prettyFingerPrint()
    /// - returns:  the fingerprint string.
    public func prettyFingerPrint() -> String {
        let upper = uppercased()
        var totalCount = 0
        var packCount = 0
        var currentPack = ""
        var result = ""
        for character in upper {
            if totalCount != 0 && totalCount % 4 == 0 {
                if packCount == 5 {
                    result += "  "
                } else if packCount > 0 {
                    result += " "
                }
                result += currentPack
                packCount += 1
                currentPack = ""
            }
            currentPack.append(character)
            totalCount += 1
        }
        if !currentPack.isEmpty {
            result += " \(currentPack)"
        }
        return result
    }
}
