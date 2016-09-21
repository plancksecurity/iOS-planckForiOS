//
//  DeleteFolderOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 19/09/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit
import CoreData

public class DeleteFolderOperation: ConcurrentBaseOperation {
    let comp = "DeleteFolderOperation"

    let accountEmail: String
    let connectionManager: ConnectionManager
    var folderName: String
    var imapSync: ImapSync!

    public init(accountEmail: String, folderName: String,
                coreDataUtil: ICoreDataUtil, connectionManager: ConnectionManager) {
        self.connectionManager = connectionManager
        self.accountEmail = accountEmail
        self.folderName = folderName
        super.init(coreDataUtil: coreDataUtil)
    }

    convenience public init(folder: IFolder, connectionManager: ConnectionManager,
                            coreDataUtil: ICoreDataUtil) {
        self.init(accountEmail: folder.account.email, folderName: folder.name,
                  coreDataUtil: coreDataUtil, connectionManager: connectionManager)
    }

    public override func main() {
        privateMOC.performBlock() {
            guard let account = self.model.accountByEmail(self.accountEmail) else {
                self.addError(Constants.errorCannotFindAccountForEmail(
                    self.comp, email: self.accountEmail))
                return
            }

            self.imapSync = self.connectionManager.emailSyncConnection(account.connectInfo)
            self.imapSync.delegate = self
            self.imapSync.start()
        }
    }

    func deleteLocalFolderAndFinish() {
        privateMOC.performBlock() {
            if let folder = self.model.folderByName(
                self.folderName, email: self.accountEmail) {
                self.privateMOC.deleteObject(folder as! NSManagedObject)
                self.model.save()
            }
            self.markAsFinished()
        }
    }
}

extension DeleteFolderOperation: ImapSyncDelegate {
    public func authenticationCompleted(sync: ImapSync, notification: NSNotification?) {
        if !self.cancelled {
            imapSync.deleteFolderWithName(folderName)
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

    public func folderAppendFailed(sync: ImapSync, notification: NSNotification?) {
        addError(Constants.errorIllegalState(comp, stateName: "folderAppendFailed"))
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
        addError(Constants.errorIllegalState(comp, stateName: "folderCreateCompleted"))
        markAsFinished()
    }

    public func folderCreateFailed(sync: ImapSync, notification: NSNotification?) {
        addError(Constants.errorIllegalState(comp, stateName: "folderCreateFailed"))
        markAsFinished()
    }

    public func folderDeleteCompleted(sync: ImapSync, notification: NSNotification?) {
        deleteLocalFolderAndFinish()
    }

    public func folderDeleteFailed(sync: ImapSync, notification: NSNotification?) {
        addError(Constants.errorFolderDeleteFailed(comp, name: folderName))
        markAsFinished()
    }

    public func actionFailed(sync: ImapSync, error: NSError) {
        addError(error)
        markAsFinished()
    }
}