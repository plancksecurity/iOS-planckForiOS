//
//  AppendSingleMessageOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 26/08/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit
import CoreData

open class AppendSingleMessageOperation: ConcurrentBaseOperation {
    let comp = "AppendSingleMessageOperation"

    let messageID: NSManagedObjectID

    let targetFolderID: NSManagedObjectID?
    let folderType: FolderType?

    let accountID: NSManagedObjectID

    let connectInfo: ConnectInfo

    let connectionManager: ConnectionManager

    var imapSync: ImapSync!

    var cwMessageToAppend: CWIMAPMessage!
    var targetFolderName: String!

    public init(message: IMessage, account: IAccount, targetFolder: IFolder?,
                folderType: FolderType?,
                connectionManager: ConnectionManager, coreDataUtil: ICoreDataUtil) {
        self.messageID = (message as! Message).objectID

        if let folder = targetFolder {
            self.targetFolderID = (folder as! Folder).objectID
        } else {
            self.targetFolderID = nil
        }
        self.folderType = folderType

        self.accountID = (account as! Account).objectID

        self.connectInfo = account.connectInfo
        self.connectionManager = connectionManager

        super.init(coreDataUtil: coreDataUtil)
    }

    convenience public init(message: IMessage, account: IAccount, targetFolder: IFolder,
                            connectionManager: ConnectionManager,
                            coreDataUtil: ICoreDataUtil) {
        self.init(message: message, account: account, targetFolder: targetFolder,
                  folderType: nil, connectionManager: connectionManager,
                  coreDataUtil: coreDataUtil)
    }

    convenience public init(message: IMessage, account: IAccount, folderType: FolderType,
                            connectionManager: ConnectionManager,
                            coreDataUtil: ICoreDataUtil) {
        self.init(message: message, account: account, targetFolder: nil,
                  folderType: folderType, connectionManager: connectionManager,
                  coreDataUtil: coreDataUtil)
    }

    override open func main() {
        privateMOC.perform({
            guard let message = self.privateMOC.object(with: self.messageID) as?
                IMessage else {
                    return
            }
            guard let account = self.privateMOC.object(with: self.accountID) as?
                IAccount else {
                    return
            }
            var tf: Folder?
            if let ft = self.folderType {
                tf = self.model.folderByType(ft, email: account.email) as? Folder
            } else if let folderID = self.targetFolderID {
                tf = self.privateMOC.object(with: folderID) as? Folder
            }

            guard let targetFolder = tf else {
                self.addError(Constants.errorCannotStoreMail(self.comp))
                self.markAsFinished()
                return
            }

            message.folder = targetFolder

            // In case the append fails, the mail will be easy to find
            message.uid = 0

            self.targetFolderName = targetFolder.name
            CoreDataUtil.saveContext(self.privateMOC)

            // Encrypt mail
            let session = PEPSession.init()
            let ident = PEPUtil.identityFromAccount(account, isMyself: true)
                as [AnyHashable: Any]
            let pepMailOrig = PEPUtil.pepMail(message)
            var encryptedMail: NSDictionary? = nil
            let status = session.encryptMessageDict(
                pepMailOrig, identity: ident, dest: &encryptedMail)
            let (mail, _) = PEPUtil.checkPepStatus(self.comp, status: status,
                encryptedMail: encryptedMail)
            if let m = mail {
                // Append the email
                self.cwMessageToAppend = PEPUtil.pantomimeMailFromPep(m as PEPMail)
                self.imapSync = self.connectionManager.emailSyncConnection(self.connectInfo)
                self.imapSync.delegate = self
                self.imapSync.start()
            }
        })
    }
}

extension AppendSingleMessageOperation: ImapSyncDelegate {
    public func authenticationCompleted(_ sync: ImapSync, notification: Notification?) {
        if !self.isCancelled {
            let folder = CWIMAPFolder.init(name: targetFolderName)
            folder.setStore(sync.imapStore)
            guard let rawData = cwMessageToAppend.dataValue() else {
                markAsFinished()
                return
            }
            folder.appendMessage(fromRawSource: rawData, flags: nil, internalDate: nil)
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
        privateMOC.perform({
            let message = self.privateMOC.object(with: self.messageID)
            self.privateMOC.delete(message)
            CoreDataUtil.saveContext(self.privateMOC)
            self.markAsFinished()
        })
    }

    public func folderAppendFailed(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorAppendFailed(comp, folderName: targetFolderName))
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
        addError(Constants.errorIllegalState(comp, stateName: "folderDeleteCompleted"))
        markAsFinished()
    }

    public func folderDeleteFailed(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorIllegalState(comp, stateName: "folderDeleteFailed"))
        markAsFinished()
    }

    public func actionFailed(_ sync: ImapSync, error: NSError) {
        addError(error)
        markAsFinished()
    }
}
