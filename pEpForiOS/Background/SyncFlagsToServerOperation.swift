//
//  SyncFlagsToServerOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 31/08/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit
import CoreData

import MessageModel

open class SyncFlagsToServerOperation: ConcurrentBaseOperation {
    let comp = "SyncFlagsToServerOperation"

    let connectionManager: ConnectionManager

    var targetFolderName: String!

    let connectInfo: EmailConnectInfo

    var imapSync: ImapSync!

    open var numberOfMessagesSynced = 0

    public init(folder: CdFolder,
                connectionManager: ConnectionManager, coreDataUtil: CoreDataUtil) {
        
        /* XXX: To be refactored."
        self.connectInfo = folder.account.connectInfo
        */
        self.connectInfo = EmailConnectInfo(accountObjectID: folder.objectID,
                                            serverObjectID: folder.objectID, // TODO: This is a lie!
                                            userName: "",
                                            networkAddress: "", networkPort: 007)
        self.targetFolderName = folder.name
        self.connectionManager = connectionManager
    }

    open override func main() {
        privateMOC.perform() {
            // Immediately check for work. If there is none, bail out
            if let _ = self.nextMessageToBeSynced() {
                self.imapSync = self.connectionManager.emailSyncConnection(self.connectInfo)
                self.imapSync.delegate = self
                self.imapSync.start()
            } else {
                self.markAsFinished()
            }
        }
    }

    func nextMessageToBeSynced() -> CdMessage? {
        let pFlagsChanged = NSPredicate.init(format: "flags != flagsFromServer")
        let pFolder = NSPredicate.init(format: "folder.name = %@",
                                       self.targetFolderName)
        let p = NSCompoundPredicate.init(
            andPredicateWithSubpredicates: [pFlagsChanged, pFolder])
        let messages = self.model.messagesByPredicate(
            p, sortDescriptors: [NSSortDescriptor.init(
                key: "receivedDate", ascending: true)])
        return messages?.first
    }

    func syncNextMessage() {
        privateMOC.perform() {
            guard let m = self.nextMessageToBeSynced() else {
                self.markAsFinished()
                return
            }
            self.updateFlagsForMessage(m)
        }
    }

    func updateFlagsForMessage(_ message: CdMessage) {
        let (cmd, dict) = message.storeCommandForUpdate()
        imapSync.imapStore.send(
            IMAP_UID_STORE, info: dict as [AnyHashable: Any], string: cmd)
    }

    func errorOperation(_ localizedMessage: String, logMessage: String) {
        markAsFinished()
        addError(Constants.errorOperationFailed(comp, errorMessage: localizedMessage))
        Log.error(component: comp, errorString: logMessage)
    }
}

extension SyncFlagsToServerOperation: ImapSyncDelegate {
    public func authenticationCompleted(_ sync: ImapSync, notification: Notification?) {
        if !self.isCancelled {
            sync.openMailBox(targetFolderName)
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
    }

    public func folderOpenCompleted(_ sync: ImapSync, notification: Notification?) {
        syncNextMessage()
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
        guard let n = notification else {
            errorOperation(NSLocalizedString(
                "UID STORE: Response with missing notification object",
                comment: "Technical error"), logMessage:
                "messageStoreCompleted with nil notification")
            return
        }
        privateMOC.perform() {
            guard let dict = (n as NSNotification).userInfo else {
                self.errorOperation(NSLocalizedString(
                    "UID STORE: Response with missing user info",
                    comment: "Technical error"),
                    logMessage: "messageStoreCompleted notification without user info")
                return
            }
            guard let cwMessages = dict[PantomimeMessagesKey] as? [CWIMAPMessage] else {
                self.errorOperation(NSLocalizedString(
                    "UID STORE: Response without messages",
                    comment: "Technical error"),
                    logMessage: "messageStoreCompleted no messages")
                return
            }
            for cw in cwMessages {
                if let msg = self.model.messageByUID(Int(cw.uid()),
                    folderName: self.targetFolderName) {
                    let flags = cw.flags()
                    msg.flags = NSNumber.init(value: flags.rawFlagsAsShort() as Int16)
                    msg.flagsFromServer = msg.flags
                } else {
                    self.errorOperation(NSLocalizedString(
                        "UID STORE: Response for message that can't be found",
                        comment: "Technical error"), logMessage:
                        "messageStoreCompleted message not found, UID: \(cw.uid())")
                }
            }
            self.model.save()
            self.numberOfMessagesSynced += 1
        }
        syncNextMessage()
    }

    public func messageStoreFailed(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorMessageStoreFailed(comp))
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
