//
//  AppendSingleMessageOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 26/08/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import CoreData

import MessageModel

open class AppendSingleMessageOperation: ConcurrentBaseOperation {
    let comp = "AppendSingleMessageOperation"

    let messageID: NSManagedObjectID

    let targetFolderID: NSManagedObjectID?
    let folderType: FolderType?

    let accountID: NSManagedObjectID

    let connectInfo: EmailConnectInfo

    let connectionManager: ConnectionManager

    var imapSync: ImapSync!

    var cwMessageToAppend: CWIMAPMessage!
    var targetFolderName: String!

    public init(connectInfo: EmailConnectInfo, message: CdMessage, account: CdAccount,
                targetFolder: CdFolder? = nil, folderType: FolderType? = nil,
                connectionManager: ConnectionManager) {
        self.connectInfo = connectInfo
        self.messageID = message.objectID
        self.targetFolderID = targetFolder?.objectID
        self.folderType = folderType
        self.accountID = account.objectID
        self.connectionManager = connectionManager
    }

    override open func main() {
        privateMOC.perform({
            guard let message = self.privateMOC.object(with: self.messageID) as?
                CdMessage else {
                    self.addError(Constants.errorCannotFindAccount(component: self.comp))
                    self.markAsFinished()
                    return
            }
            guard let account = self.privateMOC.object(with: self.accountID) as?
                CdAccount else {
                    self.addError(Constants.errorCannotFindAccount(component: self.comp))
                    self.markAsFinished()
                    return
            }
            var tf: CdFolder?
            if let ft = self.folderType {
                tf = CdFolder.by(folderType: ft, account: account)
            } else if let folderID = self.targetFolderID {
                tf = self.privateMOC.object(with: folderID) as? CdFolder
            }

            guard let targetFolder = tf else {
                self.addError(Constants.errorCannotStoreMail(self.comp))
                self.markAsFinished()
                return
            }

            message.parent = targetFolder

            // In case the append fails, the mail will be easy to find
            message.uid = 0

            self.targetFolderName = targetFolder.name
            Record.saveAndWait(context: self.privateMOC)

            // Encrypt mail
            let session = PEPSession.init()
            let ident = PEPUtil.identity(account: account)
            let pepMailOrig = PEPUtil.pEp(mail: message)
            var encryptedMail: NSDictionary? = nil
            let status = session.encryptMessageDict(
                pepMailOrig,
                identity: ident,
                dest: &encryptedMail)
            let (mail, _) = PEPUtil.checkPepStatus(self.comp, status: status,
                encryptedMail: encryptedMail)
            if let m = mail {
                // Append the email
                self.cwMessageToAppend = PEPUtil.pantomimeMailFromPep(m as! PEPMessage)
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
            Record.saveAndWait(context: self.privateMOC)
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
