//
//  PersistentSetup.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 23/06/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit
import XCTest

import pEpForiOS

class PersistentSetup {
    let coreDataUtil: ICoreDataUtil
    let connectionInfo = TestData.connectInfo
    let connectionManager = ConnectionManager.init()
    let backgroundQueue = OperationQueue.init()
    let grandOperator: GrandOperator
    let folderBuilder: ImapFolderBuilder
    let model: ICdModel
    var accountEmail: String {
        return connectionInfo.email
    }
    let account: Account

    /**
     Sets up persistence with an in-memory core data backend.
     */
    init() {
        coreDataUtil = InMemoryCoreDataUtil.init()
        grandOperator = GrandOperator.init(
            connectionManager: connectionManager, coreDataUtil: coreDataUtil)
        folderBuilder = ImapFolderBuilder.init(coreDataUtil: coreDataUtil,
                                               connectInfo: connectionInfo,
                                               backgroundQueue: backgroundQueue)

        model = CdModel.init(context: coreDataUtil.managedObjectContext)
        account = model.insertAccountFromConnectInfo(connectionInfo)
    }

    deinit {
        grandOperator.shutdown()
    }

    func inboxFolderPredicate() -> NSPredicate {
        let p = NSPredicate.init(format: "account.email = %@ and name = %@",
                                 connectionInfo.email, ImapSync.defaultImapInboxName)
        return p
    }
}
