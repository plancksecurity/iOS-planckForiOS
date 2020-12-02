//
//  UnappendableArray.swift
//  MessageModel
//
//  Created by Andreas Buff on 29.03.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation

// Crippled array you can basically do nothing but storing elements with.
public struct UnappendableArray<T> {
    public typealias UnappendableArrayType = [T]
    let array: [T]

    public init(array: [T]? = nil) {
        self.array = array ?? [T]()
    }

    public var allObjects: [T] {
        return array
    }
}

extension UnappendableArray: Collection {
    // Tell Swift what our collection contains
    public typealias Index = UnappendableArrayType.Index
    public typealias Element = UnappendableArrayType.Element

    // The upper bounds of the collection, used in iterations
    public var startIndex: Index {
        return array.startIndex
    }

    // The lower bounds of the collection, used in iterations
    public var endIndex: Index {
        return array.endIndex
    }

    public subscript(index: Index) -> T {
        get {
            return array[index]
        }
    }

    // Method that returns the next index when iterating
    public func index(after i: Index) -> Index {
        return array.index(after: i)
    }
}
