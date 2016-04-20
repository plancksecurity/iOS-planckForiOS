//
//  GrandOperator.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 15/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation

class GrandOperator {

    var errors: [NSError] = []

    let prefetchQueue = NSOperationQueue.init()
    let connectionManager: ConnectionManager
    let coreDataUtil: CoreDataUtil

    init(connectionManager: ConnectionManager, coreDataUtil: CoreDataUtil) {
        self.connectionManager = connectionManager
        self.coreDataUtil = coreDataUtil
    }

    func prefetchEmailsImap(connectInfo: ConnectInfo, folder: String?,
                            completionBlock: ((op: PrefetchEmailsOperation) -> Void)?)
        -> PrefetchEmailsOperation {
            let op = PrefetchEmailsOperation.init(grandOperator: self, connectInfo: connectInfo,
                                                  folder: folder)
            if let block = completionBlock {
                op.completionBlock = {
                    block(op: op)
                }
            }
            op.start()
            return op
    }

    func addError(error: NSError) {
        errors.append(error)
        Log.error("GrandOperator", error: error)
    }

}