//
//  Weak.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 21.04.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

/**
 Container for weak values.
 Useful for putting weak values into containers like arrays.
 */
class Weak<T: AnyObject> {
    weak var value : T?
    init (value: T) {
        self.value = value
    }
}

/**
 Container for weak values that are Hashable and therefore Equatable,
 delegating to their values.
 Useful for putting weak values into containers like arrays.
 */
class WeakHashable<T: AnyObject>: Hashable where T: Hashable {
    weak var value : T?

    var hashValue: Int {
        return value?.hashValue ?? 0
    }

    init (value: T) {
        self.value = value
    }
}

/**
 - Note: weakHashable.nil == otherWeakHashable.nil, weakHashable.nil != otherWeakHashable.value.
 */
func ==<T>(left: WeakHashable<T>, right: WeakHashable<T>) -> Bool {
    if let l = left.value, let r = right.value {
        return l == r
    }
    if left.value == nil && right.value == nil {
        return true
    }
    return false
}
