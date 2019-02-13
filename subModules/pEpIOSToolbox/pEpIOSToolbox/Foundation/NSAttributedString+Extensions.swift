//
//  NSAttributedString+Extensions.swift
//  pEp
//
//  Created by Andreas Buff on 12.12.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

extension NSAttributedString {

    /// Concatenates two attributed strings.
    ///
    /// - Parameters:
    ///   - lhs: first string
    ///   - rhs: string to concatenate to first string
    /// - Returns: lhs + rhs concatenated
    static public func +(lhs: NSAttributedString, rhs: NSAttributedString) -> NSAttributedString {
        let result = NSMutableAttributedString()
        result.append(lhs)
        result.append(rhs)
        return result
    }

    /// Concatenates two strings.
    ///
    /// - Parameters:
    ///   - lhs: first string
    ///   - rhs: string to concatenate to first string
    /// - Returns: lhs + rhs concatenated
    static public func +(lhs: NSAttributedString, rhs: String) -> NSAttributedString {
        let result = NSMutableAttributedString()
        result.append(lhs)
        let attributedRhs = NSAttributedString(string: rhs)
        result.append(attributedRhs)
        return result
    }
}
