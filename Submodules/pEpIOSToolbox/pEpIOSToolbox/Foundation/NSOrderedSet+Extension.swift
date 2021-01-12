//
//  NSOrderedSet+Extension.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 30/10/16.
//  Copyright © 2016 pEp Security S.A. All rights reserved.
//

import UIKit

extension NSOrderedSet {

    // MARK: - Adding objects

    static public func add<T>(elements: [T], toSet: NSOrderedSet?) -> NSOrderedSet? {
        if elements.isEmpty {
            return toSet
        }
        if let set = toSet {
            let newSet = NSMutableOrderedSet(array: set.array)
            newSet.addObjects(from: elements)
            return newSet
        }
        return NSOrderedSet(array: elements)
    }

    static public func add<T>(element: T, toSet: NSOrderedSet?) -> NSOrderedSet? {
        return self.add(elements: [element], toSet: toSet)
    }

    // MARK: - Removing objects

    static public func remove<T>(elements: [T], fromSet: NSOrderedSet?) -> NSOrderedSet? {
        if elements.isEmpty {
            return fromSet
        }
        guard let set = fromSet else {
            return nil
        }

        let newSet = NSMutableOrderedSet(array: set.array)
        for removee in elements {
            let idx = newSet.index(of: removee)
            if idx == NSNotFound {
                continue
            }
            newSet.removeObject(at: idx)
        }

        return newSet
    }

    static public func remove(elements: NSOrderedSet, fromSet: NSOrderedSet?) -> NSOrderedSet? {
        return self.remove(elements: elements.array, fromSet: fromSet)
    }

    static public func remove<T>(element: T, fromSet: NSOrderedSet?) -> NSOrderedSet? {
        return self.remove(elements: [element], fromSet: fromSet)
    }
}
