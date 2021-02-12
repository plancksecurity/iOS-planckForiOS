//
//  String+Mailto.swift
//  pEp
//
//  Created by Martin Brude on 06/10/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation

extension String {
    /// Tries to match the given string as regular expression.
    public func firstMatch(pattern: String, rangeNumber: Int = 1) -> String? {
        do {
            let regex = try NSRegularExpression(
                pattern: pattern, options: [])
            if let match = regex.firstMatch(in: self, options: [], range: wholeRange()) {
                let r = match.range(at: rangeNumber)
                let s = (self as NSString).substring(with: r)
                return s
            }
            return nil
        } catch {
            Log.shared.errorAndCrash(error: error)
            return nil
        }
    }

    /// Replace only the first occureance of the pattern with the replacement.
    /// For example:
    /// "holahola".replaceFirst(of: "hola", with: "") will return "hola"
    /// - Parameters:
    ///   - pattern: The pattern to match
    ///   - replacement: The replacement.
    /// - Returns: The text with the replacement done.
    public func replaceFirstOccurrence(of replacee: String, with replacement: String) -> String {
        if let range = range(of: replacee) {
            return replacingCharacters(in: range, with: replacement)
        } else {
            return self
        }
    }

    /// Remove only the first occureance of the pattern.
    /// For example:
    /// "holahola".removeFirst(of: "hola") will return "hola"
    ///   - pattern: The pattern to match
    /// - Returns: The text without the first occoureance of the pattern.
    public func removeFirstOccurrence(of replacee: String) -> String {
        return replaceFirstOccurrence(of: replacee, with: "")
    }
}

extension String.SubSequence {

    /// Replace only the first occureance of the pattern with the replacement.
    /// For example:
    /// "holahola".replaceFirst(of: "hola", with: "") will return "hola"
    /// - Parameters:
    ///   - pattern: The pattern to match
    ///   - replacement: The replacement.
    /// - Returns: The string with the replacement done.
    public func replaceFirst(of pattern:String, with replacement: String) -> String {
        let selfString = String(self)
        return selfString.replaceFirstOccurrence(of: pattern, with: replacement)
    }

    /// Remove only the first occureance of the pattern.
    /// For example:
    /// "holahola".removeFirst(of: "hola") will return "hola"
    ///   - pattern: The pattern to match
    /// - Returns: The text without the first occoureance of the pattern.
    public func removeFirst(pattern: String) -> String {
        return replaceFirst(of: pattern, with: "")
    }
}
