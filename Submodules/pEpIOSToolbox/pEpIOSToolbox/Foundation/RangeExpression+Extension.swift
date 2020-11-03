//
//  NSRanges+Extension.swift
//  pEpIOSToolbox
//
//  Created by Martin Brude on 02/03/2020.
//  Copyright © 2020 pEp Security SA. All rights reserved.
//

import Foundation

extension RangeExpression where Bound == String.Index  {
    
    /// Convert a Range expresion into a NSRange
    /// - Parameter string: The text to get the range.
    func nsRange<S: StringProtocol>(in string: S) -> NSRange {
        .init(self, in: string)
    }
}
