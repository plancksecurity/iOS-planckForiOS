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
    let grandOperator: IGrandOperator

    /**
     The model gives access to the complete application model. It has access
     to the main thread's `NSManagedObjectContext`.
     */
    let model: IModel

    override init() {
        connectionManager = ConnectionManager(coreDataUtil: coreDataUtil)
        grandOperator = GrandOperator.init(connectionManager: connectionManager,
                                           coreDataUtil: coreDataUtil)
        model = Model.init(context: coreDataUtil.managedObjectContext)
    }

}
