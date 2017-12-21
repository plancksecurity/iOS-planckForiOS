//
//  NSRegularExpression+Extension.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 27/03/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

extension NSRegularExpression {
    /**
     Does the first match cover the whole string?
     */
    public func matchesWhole(string: String?) -> Bool {
        if let s = string {
            let range = rangeOfFirstMatch(in: s, options: [], range: s.wholeRange())
            return NSEqualRanges(range, s.wholeRange())
        }
        return false
    }
}
