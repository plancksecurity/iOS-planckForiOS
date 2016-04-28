//
//  TestUtil.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 28/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation

class TestUtil {
    /**
     Runs the runloop until either some time has elapsed or a predicate is true.
     */
    static func runloopFor(time: CFAbsoluteTime, until: () -> Bool) {
        let now = CFAbsoluteTimeGetCurrent()
        while CFAbsoluteTimeGetCurrent() - now < time && !until() {
            NSRunLoop.mainRunLoop().runMode(
                NSDefaultRunLoopMode, beforeDate: NSDate.distantFuture())
        }
    }

}