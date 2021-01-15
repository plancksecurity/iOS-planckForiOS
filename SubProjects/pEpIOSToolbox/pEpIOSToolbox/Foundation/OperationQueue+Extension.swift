//
//  OperationQueue+Extension.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 01/11/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation

extension OperationQueue {
    /**
     Adds all operations to the given queue, and calls the completion block once
     they all have finished.
     */
    func batch(operations: [Operation], completionBlock: (() -> Swift.Void)?) {
        let finishOp = BlockOperation(block: {
            completionBlock?()
        })
        for op in operations {
            finishOp.addDependency(op)
            addOperation(op)
        }
        addOperation(finishOp)
    }
}
