//
//  Array+UnsafePointer.swift
//  pWpIOSToolbox
//
//  Created by Andreas Buff on 16.08.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import CoreData

extension Array {

    /// Returns an autoreleasing unsave pointer to the Array.
    public var autoreleasingUnsafeMutablePointer: AutoreleasingUnsafeMutablePointer<NSArray?> {
        var createe: NSArray? = NSArray(array: self)
        return AutoreleasingUnsafeMutablePointer<NSArray?>.init(&createe)
    }
}
