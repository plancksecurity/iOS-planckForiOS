//
//  Array+SortingAndSearching.swift
//  pEp
//
//  Created by Andreas Buff on 28.08.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

extension Array {

    /*
     Should `true` if the first element should be inserted before the second one,
     `false` otherwise.
     */
    public typealias ShouldInsertFunc = (Element, Element) -> Bool

    public typealias Comparator = (Element, Element) -> ComparisonResult

    /**
     At which position should the given item be added in order to maintain the sorting?
     Binary version.
     */
    public func insertIndex(
        element: Element, shouldInsert: ShouldInsertFunc) -> Int {
        var lowerIndex = 0;
        var upperIndex = count - 1

        while (true) {
            if lowerIndex == upperIndex {
                let lower = maxIndex(x: 0, y: lowerIndex - 1)
                let upper = minIndex(x: upperIndex + 1, y: count - 1)
                return insertIndexByTraversing(
                    element: element, from: lower, to: upper, shouldInsert: shouldInsert)
            }
            if (lowerIndex > upperIndex) {
                return count
            }
            let currentIndex = (lowerIndex + upperIndex) / 2
            let currentItem = self[currentIndex]

            if shouldInsert(element, currentItem) {
                // before
                upperIndex = currentIndex - 1
            } else {
                // after
                lowerIndex = currentIndex + 1
            }
        }
    }

    func maxIndex<T: Comparable>(x: T, y: T) -> T {
        if y > x {
            return y
        }
        return x
    }

    func minIndex<T: Comparable>(x: T, y: T) -> T {
        if y < x {
            return y
        }
        return x
    }

    public func insertIndexByTraversing(element: Element, from: Int, to: Int,
                                        shouldInsert: ShouldInsertFunc) -> Int {
        if from == to {
            return from
        }
        for i in from...to {
            if shouldInsert(element, self[i]) {
                return i
            }
        }
        return to + 1
    }

    public func insertIndexByTraversing(element: Element, shouldInsert: ShouldInsertFunc) -> Int? {
        return insertIndexByTraversing(
            element: element, from: 0, to: count - 1, shouldInsert: shouldInsert)
    }

    public func binarySearch(element: Element, comparator: Comparator) -> Int? {
        var lowerIndex = 0;
        var upperIndex = count - 1

        while (true) {
            if (lowerIndex > upperIndex) {
                return nil
            }

            let currentIndex = (lowerIndex + upperIndex) / 2

            let comparison = comparator(self[currentIndex], element)

            if comparison == .orderedSame {
                return currentIndex
            } else {
                if comparison == .orderedDescending {
                    upperIndex = currentIndex - 1
                } else {
                    lowerIndex = currentIndex + 1
                }
            }
        }
    }
}
