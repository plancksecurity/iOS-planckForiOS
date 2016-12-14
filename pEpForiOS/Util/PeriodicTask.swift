//
//  PeriodicTask.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 14/12/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

open class PeriodicTask {
    public typealias OperationProvider = () -> Operation

    let maxNumberOfTasks = 2
    let operationProvider: OperationProvider
    let checkEverySecond: TimeInterval

    let workerQueue = DispatchQueue(
        label: "net.pep-security.apps.pEp.service.OperationProvider", qos: .utility, target: nil)
    let backgroundQueue = OperationQueue()

    public init(checkEvery: TimeInterval, operationProvider: @escaping OperationProvider) {
        self.checkEverySecond = checkEvery
        self.operationProvider = operationProvider
        backgroundQueue.maxConcurrentOperationCount = 1
    }

    public func start() {
        addNewWork()
    }

    func addNewWork() {
        workerQueue.async {
            self.addNewWorkInternal()
        }
    }

    func addNewWorkInternal() {
        if backgroundQueue.operationCount < maxNumberOfTasks {
            let op = operationProvider()
            op.completionBlock = {
                self.workerQueue.asyncAfter(deadline: DispatchTime.now() + self.checkEverySecond) {
                    self.addNewWork()
                }
            }
            backgroundQueue.addOperation(op)
        }
    }
}
