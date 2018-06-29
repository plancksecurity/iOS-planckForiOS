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

    // MARK: - Public API

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
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }

        let idx = indexOfObjectIfInserted(obj: object)
        set.insert(object, at: idx)
        return idx
    }
    
    public func remove(object: T) {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }

        set.remove(object)
    }
    
    public func removeObject(at index: Int) {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }

        guard isValidIndex(index) else {
            Log.shared.errorAndCrash(component: #function, errorString: "Index out of range")
            return
        }
        set.removeObject(at: index)
    }
    
    public func object(at index: Int) -> T? {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }

        guard isValidIndex(index) else {
            Log.shared.errorAndCrash(component: #function, errorString: "Index out of range")
            return nil
        }

        return set.object(at: index) as? T
    }
    
    public func index(of object: T) -> Int {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }

        let notFound = -1
        for i in 0..<set.count {
            guard let testee = set.object(at: i) as? T else {
                Log.shared.errorAndCrash(component: #function, errorString: "error casting")
                return notFound
            }
            if testee == object {
                return i
            }
        }
        return notFound
    }
    
    public func removeAllObjects() {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        set.removeAllObjects()
    }

    // MARK: -
    
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
        for i in 0..<set.count {
            guard let testee = set.object(at: i) as? T else {
                Log.shared.errorAndCrash(component: #function, errorString: "Error casing")
                return 0
            }
            if set.count == 0 {
                //set is empty
                return 0
            }
            if sortBlock(obj, testee) == .orderedAscending {
                // following object found
                return i
            }
        }
        // we would insert as the last object
        return max(0, set.count)
    }

    private func isValidIndex(_ idx: Int) -> Bool {
        return idx >= 0 && idx < set.count
    }
}
