//
//  Array+Concat.swift
//  pEpIOSToolbox
//
//  Created by Dirk Zimmermann on 21.11.19.
//  Copyright © 2019 pEp Security SA. All rights reserved.
//

import Foundation

extension Array {
    /// Flatten the array, so that [[a]] becomes [a].
    public func concat() -> Array {
        var result = Array()
        for outer in self {
            if let elementsOuter = outer as? Array {
                for elementInner in elementsOuter {
                    result.append(elementInner)
                }
            }
        }
        return result
    }
}
