//
//  SaveSentMessageOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 29/08/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import CoreData

import MessageModel

open class SaveSentMessageOperation: EncryptBaseOperation {
    var imapSync: ImapSync!

    /**
     If the sent folder could be determined, this will contain the IMAP name.
     */
    var targetFolderName: String!

    /**
     If there was an encrypted mail, this is the raw data.
     */
    var rawMessageData: Data!

    public init(encryptionData: EncryptionData) {
        super.init(comp: "SaveSentMessageOperation", encryptionData: encryptionData)
    }

    open override func main() {
        privateMOC.perform({
            guard let message = self.fetchMessage(context: self.privateMOC) else {
                    return
            }

            guard let account = message.parent?.account else {
                self.addError(Constants.errorCannotFindAccount(component: self.comp))
                return
            }

            guard let sentFolder = CdFolder.by(folderType: .sent, account: account) else {
                let msg = NSLocalizedString(
                    "No sent folder available", comment:
                    "Error message when no sent folder exists")
                self.addError(Constants.errorInvalidParameter(self.comp, errorMessage: msg))
                Log.error(component: self.comp,
                    errorString: "No sent folder available")
                self.markAsFinished()
                return
            }

            guard let msg = self.encryptionData.mailEncryptedForSelf else {
                let msg = NSLocalizedString(
                    "Could not save sent mail: Not encrypted", comment:
                    "Error message when no encrypted mail was given for saving as sent")
                self.addError(Constants.errorOperationFailed(self.comp, errorMessage: msg))
                Log.error(component: self.comp,
                    errorString: "Could not save sent mail: Not encrypted")
                self.markAsFinished()
                return
            }

            self.targetFolderName = sentFolder.name
            let cwMessage = PEPUtil.pantomimeMailFromPep(msg)
            self.rawMessageData = cwMessage.dataValue()

            self.imapSync = self.encryptionData.connectionManager.emailSyncConnection(
                account.connectInfo)
            self.imapSync.delegate = self
            self.imapSync.start()
        })
    }
}

extension SaveSentMessageOperation: ImapSyncDelegate {
    public func authenticationCompleted(_ sync: ImapSync, notification: Notification?) {
        if !self.isCancelled {
            let folder = CWIMAPFolder.init(name: targetFolderName)
            folder.setStore(sync.imapStore)
            folder.appendMessage(fromRawSource: rawMessageData, flags: nil, internalDate: nil)
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
        privateMOC.perform() {
            guard let message = self.privateMOC.object(
                with: self.encryptionData.messageID) as? CdMessage else {
                    let error = Constants.errorInvalidParameter(
                        self.comp,
                        errorMessage:
                        NSLocalizedString("Email for encryption could not be accessed",
                                          comment: "Error message when message to encrypt could not be found."))
                    self.handleEntryError(error,
                                          message: "Email for encryption could not be accessed")
                    return
            }

            self.privateMOC.delete(message)
            CoreDataUtil.saveContext(self.privateMOC)
            self.markAsFinished()
        }
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
