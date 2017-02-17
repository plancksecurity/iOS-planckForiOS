//
//  LimitedOperationQueue.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 15/12/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

/**
 A serialized `OperationQueue` that limits the number of operations in the queue to 2.
 Useful for throttling the ongoing enqueueing of the *same* operation.
 */
open class LimitedOperationQueue: OperationQueue {
    let workerQueue = DispatchQueue(label: "LimitedOperationQueue", qos: .utility, target: nil)

    public override init() {
        super.init()
        maxConcurrentOperationCount = 1
    }

    open override func addOperation(_ op: Operation) {
        workerQueue.async {
            if self.operationCount < 2 {
                super.addOperation(op)
            }
        }
    }

    public func asyncAfter(deadline: DispatchTime, execute: @escaping  () -> Void) {
        workerQueue.asyncAfter(deadline: deadline, execute: execute)
    }
}
