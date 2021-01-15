//
//  Array+Extension.swift
//  pEpIOSToolbox
//
//  Created by Martín Brude on 29/12/20.
//  Copyright © 2020 pEp Security SA. All rights reserved.
//

import Foundation

extension Array where Element: Hashable {
    /// Retrieves a different instance with unique values keeping the original order
    public var uniques: Array {
        var buffer = Array()
        var added = Set<Element>()
        for element in self {
            if !added.contains(element) {
                buffer.append(element)
                added.insert(element)
            }
        }
        return buffer
    }
}
