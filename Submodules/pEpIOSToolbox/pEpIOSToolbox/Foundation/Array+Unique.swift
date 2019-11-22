//
//  Array+Unique.swift
//  pEpIOSToolbox
//
//  Created by Dirk Zimmermann on 22.11.19.
//  Copyright © 2019 pEp Security SA. All rights reserved.
//

import Foundation

extension Array where Element: Hashable {
    /// Creates a new array with all duplicates removed.
    public func uniques() -> Array {
        var result = Array()
        var elementsAlreadyAdded = Set<Element>()
        for elem in self {
            if !elementsAlreadyAdded.contains(elem) {
                result.append(elem)
                elementsAlreadyAdded.insert(elem)
            }
        }
        return result
    }
}
