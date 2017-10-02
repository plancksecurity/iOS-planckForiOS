//
//  SortedSet.swift
//  pEp
//
//  Created by Andreas Buff on 02.10.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit

/// Automatically keeps containted objects sorted to the criteria of a given sort block.
/// The implementation is completely trival and unperformant.
/// Has to be improved if this causes performance issue in the app.
class SortedSet<T: Equatable> {
    typealias SortBlock = (_ first: T,_  second: T) -> ComparisonResult
    private var set = NSMutableOrderedSet()
    private var sortBlock: SortBlock

    public var count: Int {
        return set.count
    }

    init(array: [T], sortBlock block: @escaping SortBlock) {
        set = NSMutableOrderedSet(array: array)
        sortBlock = block
        sort()
    }

    /// Inserts an object keeping the Set sorted. Returns the index it has been inserted to.
    ///
    /// - Parameter object: object to insert
    /// - Returns: index the object has been inserted to
    public func insert(object: T) -> Int {
        let idx = indexOfObjectIfInserted(obj: object)
        set.insert(object, at: idx)
        return idx
    }

    public func remove(object: T) {
        set.remove(object)
    }

    public func object(at index: Int) -> T? {
        return set.object(at: index) as? T
    }

    public func index(of object: T) -> Int{
        return set.index(of: object)
    }

    public func removeAllObjects() {
        set.removeAllObjects()
    }

    private func sort()  {
        set.sort { (first: Any, second: Any) -> ComparisonResult in
            guard let firstT = first as? T,
                let secondT = second as? T else {
                    Log.shared.errorAndCrash(component: #function, errorString: "Error casting.")
                    return .orderedSame
            }
            return sortBlock(firstT, secondT)
        }
    }

    private func indexOfObjectIfInserted(obj: T) -> Int {
        var index = 0
        for i in 0..<set.count {
            guard let testee = set.object(at: i) as? T else {
                Log.shared.errorAndCrash(component: #function, errorString: "Error casing")
                return index
            }

            if sortBlock(obj, testee) != .orderedAscending {
                index = i
            }
        }
        return index
    }
}
