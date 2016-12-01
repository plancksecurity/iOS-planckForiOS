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
    open fileprivate(set) var refCount: Int = 0

    public init() {}

    public init(refCount: Int) {
        self.refCount = refCount
    }

    open func inc() {
        refCount = refCount + 1
    }

    open func dec() {
        refCount = refCount - 1
    }
}
