//
//  MutableOrderedSet.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 12/10/16.
//  Copyright © 2016 pEp Security S.A. All rights reserved.
//

import Foundation

open class MutableOrderedSet<T>: Sequence {
    public init() {}

    public init(array: [T]) {
        for e in array {
            elements.add(e)
        }
    }

    open var array: [T] {
        return elements.array as? [T] ?? []
    }

    open subscript(safe index: Int) -> T? {
        get {
            if elements.count == 0 {
                return nil
            }
            if index >= elements.count {
                return nil
            }
            if let e = elements.object(at: index) as? T {
                return e
            }
            return nil
        }
    }

    open var count: Int {
        get {
            return elements.count
        }
    }

    open var isEmpty: Bool {
        get {
            return elements.count == 0
        }
    }

    open func append(_ element: T) {
        elements.add(element)
    }

    open func insert(_ element: T) {
        self.append(element)
    }

    open func contains(_ element: T) -> Bool {
        return elements.contains(element)
    }

    open func remove(_ element: T) {
        elements.remove(element)
    }

    open func indexOf(_ element: T) -> Int? {
        let i = elements.index(of: element)
        if i == NSNotFound {
            return nil
        } else {
            return i
        }
    }

    private var elements = NSMutableOrderedSet()

    // MARK: - Sequence

    public typealias Iterator = MutableOrderedSetIterator<T>

    public func makeIterator() -> MutableOrderedSet.Iterator {
        return MutableOrderedSetIterator(elements: elements.array as! [T])
    }

    // MARK: - Iterator

    public struct MutableOrderedSetIterator<T>: IteratorProtocol {
        public typealias Element = T

        private let elements: [T]
        private var index = 0
        private let maxIndex: Int

        public init(elements: [T]) {
            self.elements = elements
            maxIndex = elements.count - 1
        }

        public mutating func next() -> MutableOrderedSetIterator.Element? {
            if index > maxIndex {
                return nil
            } else {
                let e = elements[index]
                index += 1
                return e
            }
        }
    }
}
