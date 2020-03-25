//
//  NSString+firstLetterCompare.swift
//  pEpIOSToolbox
//
//  Created by Dirk Zimmermann on 25.03.20.
//  Copyright © 2020 pEp Security SA. All rights reserved.
//

import Foundation

extension NSString {
    public func firstLetter() -> String {
        let first = substring(to: 1)
        if first.isLetter && first != "" {
            return first.uppercased()
        } else {
            return "#"
        }
    }

    @objc
    public func firstLetterCompare(_ string: String) -> ComparisonResult {
        let s1 = firstLetter()
        let s2 = string.firstLetter()
        return s1.compare(s2)
    }
}
