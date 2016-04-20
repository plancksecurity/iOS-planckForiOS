//
//  AppConfig.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 12/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation

/**
 Some cross cutting concerns, like core data access, networking, etc.
 */
class AppConfig: NSObject {

    let coreDataUtil: CoreDataUtil = CoreDataUtil()
    let connectionManager: ConnectionManager
    let grandOperator: GrandOperator

    override init() {
        connectionManager = ConnectionManager(coreDataUtil: coreDataUtil)
        grandOperator = GrandOperator.init(connectionManager: connectionManager,
                                           coreDataUtil: coreDataUtil)
    }

}
