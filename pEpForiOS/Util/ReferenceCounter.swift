//
//  ReferenceCounter.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 27/05/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

/**
 Primitive class to verify memory leaks.
 */
open class ReferenceCounter {
    struct Entry {
        let index: UnsafeRawPointer
        let description: String
        var count: Int

        init(obj: AnyObject) {
            description = String(describing: obj)
            index = unsafeBitCast(obj, to: UnsafeRawPointer.self)
            count = 0
        }

        mutating func inc() {
            count += 1
        }

        mutating func dec() {
            count -= 1
        }
    }

    static var table = [UnsafeRawPointer: Entry]()

    static func fromTable(obj: AnyObject) -> Entry {
        let entry = Entry(obj: obj)
        let actual = table[entry.index] ?? entry
        return actual
    }

    static func toTable(entry: Entry) {
        table[entry.index] = entry
    }

    public static func inc(obj: AnyObject) {
        var entry = fromTable(obj: obj)
        entry.inc()
        toTable(entry: entry)
    }

    public static func dec(obj: AnyObject) {
        var entry = fromTable(obj: obj)
        entry.dec()
        toTable(entry: entry)
    }

    public static func logOutstanding() {
        for (_, entry) in table {
            if entry.count != 0 {
                Logger.utilLogger.warn("%{public}@", entry.description)
            }
        }
    }
}
