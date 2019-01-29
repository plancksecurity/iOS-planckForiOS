//
//  String+Extension+temp.swift
//  pEpUtilities
//
//  Created by Xavier Algarra on 29/01/2019.
//  Copyright © 2019 pEp Security SA. All rights reserved.
//

import Foundation

extension String {
    public func wholeRange() -> NSRange {
        return NSRange(location: 0, length: count)
    }
}
