//
//  AppConfig.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 12/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel

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
    let model: ICdModel

    /**
     As soon as the UI has at least one account that is in use, this is set here.
     */
    var currentAccount: Account? = nil

    override init() {
        connectionManager = ConnectionManager()
        model = CdModel.init(context: coreDataUtil.defaultContext())
        let gOp = GrandOperator.init(connectionManager: connectionManager,
                                     coreDataUtil: coreDataUtil)
        grandOperator = gOp
        MessageModel.CdAccount.sendLayer = gOp

    }

}
