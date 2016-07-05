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
    let backgroundQueue = NSOperationQueue.init()
    let grandOperator: GrandOperator
    let folderBuilder: ImapFolderBuilder
    let model: IModel
    var accountEmail: String {
        return connectionInfo.email
    }

    /**
     Sets up persistence with an in-memory core data backend.
     */
    init() {
        coreDataUtil = InMemoryCoreDataUtil.init()
        grandOperator = GrandOperator.init(
            connectionManager: connectionManager, coreDataUtil: coreDataUtil)
        folderBuilder = ImapFolderBuilder.init(grandOperator: grandOperator,
                                               connectInfo: connectionInfo,
                                               backgroundQueue: backgroundQueue)

        model = Model.init(context: coreDataUtil.managedObjectContext)
        let account = model.insertAccountFromConnectInfo(connectionInfo)
        XCTAssertNotNil(account)
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
