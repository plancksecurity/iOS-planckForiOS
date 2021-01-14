//
//  StringProtocol+NSRanges.swift
//  pEpIOSToolbox
//
//  Created by Martin Brude on 02/03/2020.
//  Copyright © 2020 pEp Security SA. All rights reserved.
//

import Foundation

extension StringProtocol {

    /// Obtains the NSRange of certaint text.
    /// Usage example:
    /// "This is a wonderful method".nsRange(of: "wonderful") returns a NSRange with location 10, lenght 9.
    ///
    /// - Parameters:
    ///   - string: The base text that might contantains the substring
    ///   - options: Represents the options to search and compare.
    ///   - range: The range where to look for the subtext. If nil, will search in the complete text.
    ///   - locale: If not specified will use the current locale.
    /// - Returns: The range of the text passed by parameter. If it's not found returns nil.
    public func nsRange<S: StringProtocol>(of string: S, options: String.CompareOptions = [], range: Range<Index>? = nil, locale: Locale? = nil) -> NSRange? {
        self.range(of: string,
                   options: options,
                   range: range ?? startIndex..<endIndex,
                   locale: locale ?? .current)?
            .nsRange(in: self)
    }
}
