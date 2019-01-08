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
        workerQueue.async { [weak self] in
            guard let me = self else {
                Logger.lostMySelf(category: Logger.backend)
                return
            }
            if me.operationCount < 2 {
                me.callSuperAddOperation(op: op)
            }
        }
    }

    /// Works around a swift issue:
    // "Using 'super' in a closure where 'self' is explicitly captured is not yet supported"
    private func callSuperAddOperation(op: Operation) {
        super.addOperation(op)
    }

    public func asyncAfter(deadline: DispatchTime, execute: @escaping  () -> Void) {
        workerQueue.asyncAfter(deadline: deadline, execute: execute)
    }
}
