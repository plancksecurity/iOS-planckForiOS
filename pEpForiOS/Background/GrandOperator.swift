//
//  GrandOperator.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 15/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation

class GrandOperator {

    let prefetchQueue = NSOperationQueue.init()
    let connectionManager: ConnectionManager
    let coreDataUtil: CoreDataUtil

    init(connectionManager: ConnectionManager, coreDataUtil: CoreDataUtil) {
        self.connectionManager = connectionManager
        self.coreDataUtil = coreDataUtil
    }

    func prefetchEmailsImap(connectInfo: ConnectInfo, folder: String?) {
        let op = PrefetchEmailsOperation.init(grandOperator: self, connectInfo: connectInfo,
                                              folder: folder)
        op.completionBlock = {
            print("completed")
        }
        op.start()
    }

}