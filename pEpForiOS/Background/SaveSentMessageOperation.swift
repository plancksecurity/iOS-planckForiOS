//
//  SaveSentMessageOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 29/08/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit
import CoreData

public class SaveSentMessageOperation: ConcurrentBaseOperation {
    let comp = "SaveSentMessageOperation"

    /**
     All the parameters for the operation come from here.
     */
    let encryptionData: EncryptionData

    lazy var privateMOC: NSManagedObjectContext =
        self.encryptionData.coreDataUtil.privateContext()
    lazy var model: IModel = Model.init(context: self.privateMOC)

    var imapSync: ImapSync!

    /**
     If the sent folder could be determined, this will contain the IMAP name.
     */
    var targetFolderName: String!

    /**
     If there was an encrypted mail, this is the raw data.
     */
    var rawMessageData: NSData!

    public init(encryptionData: EncryptionData) {
        self.encryptionData = encryptionData
    }

    public override func main() {
        privateMOC.performBlock({
            guard let account = self.model.accountByEmail(
                self.encryptionData.accountEmail) else {
                    self.addError(Constants.errorCannotFindAccountForEmail(
                        self.comp, email: self.encryptionData.accountEmail))
                    return
            }

            guard let sentFolder = self.model.folderByType(.Sent, account: account) else {
                let msg = NSLocalizedString(
                    "No sent folder available", comment:
                    "Error message when no sent folder exists")
                self.addError(Constants.errorInvalidParameter(self.comp, errorMessage: msg))
                Log.errorComponent(self.comp,
                    errorString: "No sent folder available")
                self.markAsFinished()
                return
            }

            guard let msg = self.encryptionData.mailEncryptedForSelf else {
                let msg = NSLocalizedString(
                    "Could not save sent mail: Not encrypted", comment:
                    "Error message when no encrypted mail was given for saving as sent")
                self.addError(Constants.errorOperationFailed(self.comp, errorMessage: msg))
                Log.errorComponent(self.comp,
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
    public func authenticationCompleted(sync: ImapSync, notification: NSNotification?) {
        if !self.cancelled {
            let folder = CWIMAPFolder.init(name: targetFolderName)
            folder.setStore(sync.imapStore)
            folder.appendMessageFromRawSource(rawMessageData, flags: nil, internalDate: nil)
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

    public func actionFailed(sync: ImapSync, error: NSError) {
        addError(error)
        markAsFinished()
    }
}