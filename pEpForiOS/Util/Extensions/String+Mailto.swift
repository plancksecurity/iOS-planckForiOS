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
    /// - Returns: The string with the replacement done.
    public func replaceFirst(of pattern:String, with replacement: String) -> String {
        if let range = range(of: pattern) {
            return replacingCharacters(in: range, with: replacement)
        } else{
            return self
        }
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
}
