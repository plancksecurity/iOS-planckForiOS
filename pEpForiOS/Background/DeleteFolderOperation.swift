//
//  DeleteFolderOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 19/09/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import CoreData

import MessageModel

open class DeleteFolderOperation: ConcurrentBaseOperation {
    let comp = "DeleteFolderOperation"

    let connectInfo: EmailConnectInfo
    let connectionManager: ConnectionManager
    var folderName: String
    let accountID: NSManagedObjectID
    var account: CdAccount!
    var imapSync: ImapSync!

    public init(connectInfo: EmailConnectInfo, account: CdAccount, folderName: String,
                connectionManager: ConnectionManager) {
        self.connectInfo = connectInfo
        self.accountID = account.objectID
        self.folderName = folderName
        self.connectionManager = connectionManager
    }

    convenience public init?(connectInfo: EmailConnectInfo, folder: CdFolder,
                             connectionManager: ConnectionManager) {
        guard let fn = folder.name else {
            Log.error(component: "DeleteFolderOperation.init",
                      errorString: "Cannot delete folder without name")
            return nil
        }
        guard let account = folder.account else {
            Log.error(component: "DeleteFolderOperation.init",
                      errorString: "Cannot delete folder without account")
            return nil
        }
        self.init(connectInfo: connectInfo, account: account, folderName: fn,
                  connectionManager: connectionManager)
    }

    open override func main() {
        privateMOC.perform() {
            self.account = self.privateMOC.object(with: self.accountID) as? CdAccount
            guard self.account != nil else {
                self.addError(Constants.errorCannotFindAccount(component: self.comp))
                self.markAsFinished()
                return
            }

            self.imapSync = self.connectionManager.emailSyncConnection(self.connectInfo)
            self.imapSync.delegate = self
            self.imapSync.start()
        }
    }

    func deleteLocalFolderAndFinish() {
        privateMOC.perform() {
            if let folder = CdFolder.by(name: self.folderName, account: self.account) {
                self.privateMOC.delete(folder)
            }
            self.markAsFinished()
        }
    }
}

extension DeleteFolderOperation: ImapSyncDelegate {
    public func authenticationCompleted(_ sync: ImapSync, notification: Notification?) {
        if !self.isCancelled {
            imapSync.deleteFolderWithName(folderName)
        }
    }

    public func authenticationFailed(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorAuthenticationFailed(comp))
        markAsFinished()
    }

    public func connectionLost(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorConnectionLost(comp))
        markAsFinished()
    }

    public func connectionTerminated(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorConnectionTerminated(comp))
        markAsFinished()
    }

    public func connectionTimedOut(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorConnectionTimeout(comp))
        markAsFinished()
    }

    public func folderPrefetchCompleted(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorIllegalState(comp, stateName: "folderPrefetchCompleted"))
        markAsFinished()
    }

    public func messageChanged(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorIllegalState(comp, stateName: "messageChanged"))
        markAsFinished()
    }

    public func messagePrefetchCompleted(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorIllegalState(comp, stateName: "messagePrefetchCompleted"))
        markAsFinished()
    }

    public func folderOpenCompleted(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorIllegalState(comp, stateName: "folderOpenCompleted"))
        markAsFinished()
    }

    public func folderOpenFailed(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorIllegalState(comp, stateName: "folderOpenFailed"))
        markAsFinished()
    }

    public func folderStatusCompleted(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorIllegalState(comp, stateName: "folderStatusCompleted"))
        markAsFinished()
    }

    public func folderListCompleted(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorIllegalState(comp, stateName: "folderListCompleted"))
        markAsFinished()
    }

    public func folderNameParsed(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorIllegalState(comp, stateName: "folderNameParsed"))
        markAsFinished()
    }

    public func folderAppendCompleted(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorIllegalState(comp, stateName: "folderAppendCompleted"))
        markAsFinished()
    }

    public func folderAppendFailed(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorIllegalState(comp, stateName: "folderAppendFailed"))
        markAsFinished()
    }

    public func messageStoreCompleted(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorIllegalState(comp, stateName: "messageStoreCompleted"))
        markAsFinished()
    }

    public func messageStoreFailed(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorIllegalState(comp, stateName: "messageStoreFailed"))
        markAsFinished()
    }

    public func folderCreateCompleted(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorIllegalState(comp, stateName: "folderCreateCompleted"))
        markAsFinished()
    }

    public func folderCreateFailed(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorIllegalState(comp, stateName: "folderCreateFailed"))
        markAsFinished()
    }

    public func folderDeleteCompleted(_ sync: ImapSync, notification: Notification?) {
        deleteLocalFolderAndFinish()
    }

    public func folderDeleteFailed(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorFolderDeleteFailed(comp, name: folderName))
        markAsFinished()
    }

    public func actionFailed(_ sync: ImapSync, error: NSError) {
        addError(error)
        markAsFinished()
    }
}
