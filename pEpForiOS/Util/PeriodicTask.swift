//
//  PeriodicTask.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 14/12/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

import MessageModel

open class PeriodicTask {
    public typealias OperationProvider = () -> Operation

    let operationProvider: OperationProvider
    let checkEverySecond: TimeInterval

    let backgroundQueue = LimitedOperationQueue()

    public init(checkEvery: TimeInterval, operationProvider: @escaping OperationProvider) {
        self.checkEverySecond = checkEvery
        self.operationProvider = operationProvider
    }

    public func start() {
        addNewWork()
    }

    func addNewWork() {
        let op = operationProvider()
        op.completionBlock = {
            op.completionBlock = nil
            self.backgroundQueue.asyncAfter(deadline: DispatchTime.now() + self.checkEverySecond) {
                self.addNewWork()
            }
        }
        backgroundQueue.addOperation(op)
    }
}
