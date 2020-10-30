//
//  MutableOrderedSet.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 12/10/16.
//  Copyright © 2016 pEp Security S.A. All rights reserved.
//

import Foundation

class MutableOrderedSet<T>: Sequence {
    public init() {}

    init(array: [T]) {
        for e in array {
            elements.add(e)
        }
    }

    var array: [T] {
        return elements.array as? [T] ?? []
    }

    subscript(safe index: Int) -> T? {
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

    var count: Int {
        get {
            return elements.count
        }
    }

    var isEmpty: Bool {
        get {
            return elements.count == 0
        }
    }

    func append(_ element: T) {
        elements.add(element)
    }

    func insert(_ element: T) {
        self.append(element)
    }

    func contains(_ element: T) -> Bool {
        return elements.contains(element)
    }

    func remove(_ element: T) {
        elements.remove(element)
    }

    func indexOf(_ element: T) -> Int? {
        let i = elements.index(of: element)
        if i == NSNotFound {
            return nil
        } else {
            return i
        }
    }

    private var elements = NSMutableOrderedSet()

    // MARK: - Sequence

    typealias Iterator = MutableOrderedSetIterator<T>

    func makeIterator() -> MutableOrderedSet.Iterator {
        return MutableOrderedSetIterator(elements: elements.array as! [T])
    }

    // MARK: - Iterator

    struct MutableOrderedSetIterator<T>: IteratorProtocol {
        public typealias Element = T

        private let elements: [T]
        private var index = 0
        private let maxIndex: Int

        init(elements: [T]) {
            self.elements = elements
            maxIndex = elements.count - 1
        }

        mutating func next() -> MutableOrderedSetIterator.Element? {
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
