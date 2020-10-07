//
//  String+Mailto.swift
//  pEp
//
//  Created by Martin Brude on 06/10/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation

extension String {

    /// Replace only the first occureance of the pattern with the replacement.
    /// For example:
    /// "holahola".replaceFirst(of: "hola", with: "") will return "hola"
    /// - Parameters:
    ///   - pattern: The pattern to match
    ///   - replacement: The replacement.
    /// - Returns: The text with the replacement done.
    public func replaceFirst(of pattern: String, with replacement: String) -> String {
        if let range = range(of: pattern) {
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
    public func removeFirst(pattern: String) -> String {
        return replaceFirst(of: pattern, with: "")
    }

    public func componentsSeparatedByComma() -> [String] {
        return split {$0 == "," }.map { String($0) }
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
        return selfString.replaceFirst(of: pattern, with: replacement)
    }

    /// Remove only the first occureance of the pattern.
    /// For example:
    /// "holahola".removeFirst(of: "hola") will return "hola"
    ///   - pattern: The pattern to match
    /// - Returns: The text without the first occoureance of the pattern.
    public func removeFirst(pattern: String) -> String {
        return replaceFirst(of: pattern, with: "")
    }

    /// Splits a text that uses commas as separator.
    /// - Returns: The indepentent texts.
    public func componentsSeparatedByComma() -> [String] {
        return split {$0 == "," }.map { String($0) }
    }
}
