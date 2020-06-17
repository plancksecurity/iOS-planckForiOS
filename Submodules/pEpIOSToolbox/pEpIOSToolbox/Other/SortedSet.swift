//
//  SortedSet.swift
//  pEp
//
//  Created by Andreas Buff on 02.10.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

/// Automatically keeps containted objects sorted to the criteria of a given sort block.
/// The implementation is completely trival and unperformant.
/// Has to be improved if this causes performance issue in the app.
public class SortedSet<T: Equatable>: Sequence {
    // MARK: - Public API

    public typealias SortBlock = (_ first: T,_  second: T) -> ComparisonResult

    public var count: Int {
        return set.count
    }
    
    public init(array: [T], sortBlock block: @escaping SortBlock) {
        set = NSMutableOrderedSet(array: array)
        sortBlock = block
        sort()
    }
    
    /// Inserts an object keeping the Set sorted. Returns the index it has been inserted to.
    ///
    /// - Parameter object: object to insert
    /// - Returns: index the object has been inserted to
    @discardableResult public func insert(object: T) -> Int {
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
            Log.shared.errorAndCrash("Index out of range")
            return
        }
        set.removeObject(at: index)
    }
    
    public func replaceObject(at index: Int, with object: T) {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }

        guard isValidIndex(index) else {
            Log.shared.errorAndCrash("Index out of range")
            return
        }
        set.replaceObject(at: index, with: object)
    }

    public func object(at index: Int) -> T? {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }

        guard isValidIndex(index) else {
            Log.shared.errorAndCrash("Index out of range")
            return nil
        }

        return set.object(at: index) as? T
    }

    /**
     - Returns: The index of `object` or nil.
     */
    public func index(of object: T) -> Int? {
        let idx = indexOrNotFound(of: object)
        if idx != NSNotFound {
            return idx
        } else {
            return nil
        }
    }

    /**
     - Returns: The index of `object` or NSNotFound.
     */
    public func indexOrNotFound(of object: T) -> Int {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }

        for i in 0..<set.count {
            guard let testee = set.object(at: i) as? T else {
                Log.shared.errorAndCrash("error casting")
                return NSNotFound
            }
            if testee == object {
                return i
            }
        }
        return NSNotFound
    }
    
    public func removeAllObjects() {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        set.removeAllObjects()
    }

    // MARK: - Array Support

    public func array() -> [T] {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }

        if let theArray = set.array as? [T] {
            return theArray
        } else {
            return []
        }
    }

    public subscript(safe index: Int) -> T? {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }

        if index >= set.count {
            return nil
        }

        if let obj = set.object(at: index) as? T {
            return obj
        } else {
            return nil
        }
    }

    // MARK: - Sequence

    public typealias Iterator = SortedSetIterator<T>

    public func makeIterator() -> SortedSet<T>.SortedSetIterator<T> {
        return SortedSetIterator.init(elements: set.array as! [T])
    }

    // MARK: - Iterator

    public struct SortedSetIterator<T>: IteratorProtocol {
        public typealias Element = T

        private let elements: [T]
        private var index = 0
        private let maxIndex: Int

        public init(elements: [T]) {
            self.elements = elements
            maxIndex = elements.count - 1
        }

        public mutating func next() -> SortedSetIterator.Element? {
            if index > maxIndex {
                return nil
            } else {
                let e = elements[index]
                index += 1
                return e
            }
        }
    }

    // MARK: -
    
    private var set = NSMutableOrderedSet()
    private var sortBlock: SortBlock

    private func sort()  {
        set.sort { (first: Any, second: Any) -> ComparisonResult in
            guard let firstT = first as? T,
                let secondT = second as? T else {
                    Log.shared.errorAndCrash("Error casting.")
                    return .orderedSame
            }
            return sortBlock(firstT, secondT)
        }
    }
    
    private func indexOfObjectIfInserted(obj: T) -> Int {
        for i in 0..<set.count {
            guard let testee = set.object(at: i) as? T else {
                Log.shared.errorAndCrash("Error casing")
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
        return Swift.max(0, set.count)
    }

    private func isValidIndex(_ idx: Int) -> Bool {
        return idx >= 0 && idx < set.count
    }
}
