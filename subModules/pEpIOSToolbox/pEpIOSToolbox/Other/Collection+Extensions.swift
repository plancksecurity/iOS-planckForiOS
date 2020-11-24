//
//  Collection+Extensions.swift
//  pEpIOSToolbox
//
//  Created by Dirk Zimmermann on 11/10/16.
//  Copyright © 2016 pEp Security S.A. All rights reserved.
//

extension Collection {

    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    public subscript(safe index: Index) -> Iterator.Element? {
        return index >= startIndex && index < endIndex ? self[index] : nil
    }

    /// Count the elements in a collection that satisfy the given predicate.
    /// - Parameter predicate: The predicate to evaluate
    /// - Returns: The number of elements that satify the predicate.
    public func count(where predicate: (Element) -> Bool) -> Int {
        return filter(predicate).count
    }
}
