//
//  CheckAndCreateFolderOfTypeOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 15/09/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit
import CoreData

/**
 Can be run before operations that operate on folders, like "save draft"
 (with a dependency), to make sure that folder does exist.
 */
public class CheckAndCreateFolderOfTypeOperation: ConcurrentBaseOperation {
    let comp = "CheckAndCreateFolderOfTypeOperation"
    let folderType: FolderType
    let coreDataUtil: ICoreDataUtil
    let accountEmail: String
    let connectInfo: ConnectInfo
    let connectionManager: ConnectionManager
    let folderName: String
    var imapSync: ImapSync!

    lazy var privateMOC: NSManagedObjectContext = self.coreDataUtil.privateContext()
    lazy var model: IModel = Model.init(context: self.privateMOC)

    public init(account: IAccount, folderType: FolderType,
                connectionManager: ConnectionManager, coreDataUtil: ICoreDataUtil) {
        self.accountEmail = account.email
        self.connectInfo = account.connectInfo
        self.folderType = folderType
        self.folderName = folderType.folderName()
        self.connectionManager = connectionManager
        self.coreDataUtil = coreDataUtil
        super.init()
    }

    public override func main() {
        privateMOC.performBlock() {
            let folder = self.model.folderByType(self.folderType, email: self.accountEmail)
            if folder == nil {
                self.imapSync = self.connectionManager.emailSyncConnection(self.connectInfo)
                self.imapSync.delegate = self
                self.imapSync.start()
            } else {
                self.markAsFinished()
            }
        }
    }
}

extension CheckAndCreateFolderOfTypeOperation: ImapSyncDelegate {
    public func authenticationCompleted(sync: ImapSync, notification: NSNotification?) {
        if !self.cancelled {
            sync.createFolderWithName(folderName)
        }
    }

    public func authenticationFailed(sync: ImapSync, notification: NSNotification?) {
        addError(Constants.errorAuthenticationFailed(comp))
        markAsFinished()
    }

    public func connectionLost(sync: ImapSync, notification: NSNotification?) {
        addError(Constants.errorConnectionLost(comp))
        markAsFinished()
    }

    public func connectionTerminated(sync: ImapSync, notification: NSNotification?) {
        addError(Constants.errorConnectionTerminated(comp))
        markAsFinished()
    }

    public func connectionTimedOut(sync: ImapSync, notification: NSNotification?) {
        addError(Constants.errorConnectionTimeout(comp))
        markAsFinished()
    }

    public func folderPrefetchCompleted(sync: ImapSync, notification: NSNotification?) {
        addError(Constants.errorIllegalState(comp, stateName: "folderPrefetchCompleted"))
        markAsFinished()
    }

    public func messageChanged(sync: ImapSync, notification: NSNotification?) {
        addError(Constants.errorIllegalState(comp, stateName: "messageChanged"))
        markAsFinished()
    }

    public func messagePrefetchCompleted(sync: ImapSync, notification: NSNotification?) {
        addError(Constants.errorIllegalState(comp, stateName: "messagePrefetchCompleted"))
        markAsFinished()
    }

    public func folderOpenCompleted(sync: ImapSync, notification: NSNotification?) {
        addError(Constants.errorIllegalState(comp, stateName: "folderOpenCompleted"))
        markAsFinished()
    }

    public func folderOpenFailed(sync: ImapSync, notification: NSNotification?) {
        addError(Constants.errorIllegalState(comp, stateName: "folderOpenFailed"))
        markAsFinished()
    }

    public func folderStatusCompleted(sync: ImapSync, notification: NSNotification?) {
        addError(Constants.errorIllegalState(comp, stateName: "folderStatusCompleted"))
        markAsFinished()
    }

    public func folderListCompleted(sync: ImapSync, notification: NSNotification?) {
        addError(Constants.errorIllegalState(comp, stateName: "folderListCompleted"))
        markAsFinished()
    }

    public func folderNameParsed(sync: ImapSync, notification: NSNotification?) {
        addError(Constants.errorIllegalState(comp, stateName: "folderNameParsed"))
        markAsFinished()
    }

    public func folderAppendCompleted(sync: ImapSync, notification: NSNotification?) {
        addError(Constants.errorIllegalState(comp, stateName: "folderAppendCompleted"))
        markAsFinished()
    }

    public func messageStoreCompleted(sync: ImapSync, notification: NSNotification?) {
        addError(Constants.errorIllegalState(comp, stateName: "messageStoreCompleted"))
        markAsFinished()
    }

    public func messageStoreFailed(sync: ImapSync, notification: NSNotification?) {
        addError(Constants.errorIllegalState(comp, stateName: "messageStoreFailed"))
        markAsFinished()
    }

    public func folderCreateCompleted(sync: ImapSync, notification: NSNotification?) {
        markAsFinished()
    }

    public func folderCreateFailed(sync: ImapSync, notification: NSNotification?) {
        addError(Constants.errorFolderCreateFailed(comp, name: folderName))
        markAsFinished()
    }

    public func actionFailed(sync: ImapSync, error: NSError) {
        addError(error)
        markAsFinished()
    }
}