//
//  ReferenceCounter.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 27/05/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation

/**
 Primitive class to verify memory leaks.
 */
public class ReferenceCounter {
    public private(set) var refCount: Int = 0

    public init() {}

    public init(refCount: Int) {
        self.refCount = refCount
    }

    public func inc() {
        refCount = refCount + 1
    }

    public func dec() {
        refCount = refCount - 1
    }
}