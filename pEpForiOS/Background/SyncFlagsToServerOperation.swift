//
//  SyncFlagsToServerOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 31/08/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit
import CoreData

public class SyncFlagsToServerOperation: ConcurrentBaseOperation {
    let comp = "SyncFlagsToServerOperation"

    let connectionManager: ConnectionManager
    let coreDataUtil: ICoreDataUtil

    var targetFolderName: String!

    let connectInfo: ConnectInfo

    var imapSync: ImapSync!

    lazy var privateMOC: NSManagedObjectContext = self.coreDataUtil.privateContext()
    lazy var model: IModel = Model.init(context: self.privateMOC)

    public var numberOfMessagesSynced = 0

    public init(folder: IFolder,
                connectionManager: ConnectionManager, coreDataUtil: ICoreDataUtil) {
        self.connectInfo = folder.account.connectInfo
        self.targetFolderName = folder.name
        self.connectionManager = connectionManager
        self.coreDataUtil = coreDataUtil
    }

    public override func main() {
        self.imapSync = self.connectionManager.emailSyncConnection(self.connectInfo)
        self.imapSync.delegate = self
        self.imapSync.start()
    }

    func syncNextMessage() {
        privateMOC.performBlock() {
            let pFlagsChanged = NSPredicate.init(format: "flags != flagsFromServer")
            let pFolder = NSPredicate.init(format: "folder.name = %@",
                self.targetFolderName)
            let p = NSCompoundPredicate.init(
                andPredicateWithSubpredicates: [pFlagsChanged, pFolder])
            let messages = self.model.messagesByPredicate(
                p, sortDescriptors: [NSSortDescriptor.init(
                    key: "receivedDate", ascending: true)])
            guard let m = messages?.first else {
                self.markAsFinished()
                return
            }
            self.updateFlagsForMessage(m)
        }
    }

    func updateFlagsForMessage(message: IMessage) {
        let (cmd, dict) = message.storeCommandForUpdate()
        imapSync.imapStore.sendCommand(
            IMAP_UID_STORE, info: dict as [NSObject : AnyObject], string: cmd)
    }

    func errorOperation(localizedMessage: String, logMessage: String) {
        markAsFinished()
        addError(Constants.errorOperationFailed(comp, errorMessage: localizedMessage))
        Log.errorComponent(comp, errorString: logMessage)
    }
}

extension SyncFlagsToServerOperation: ImapSyncDelegate {
    public func authenticationCompleted(sync: ImapSync, notification: NSNotification?) {
        if !self.cancelled {
            sync.openMailBox(targetFolderName)
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
    }

    public func folderOpenCompleted(sync: ImapSync, notification: NSNotification?) {
        syncNextMessage()
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
        guard let n = notification else {
            errorOperation(NSLocalizedString(
                "UID STORE: Response with missing notification object",
                comment: "Technical error"), logMessage:
                "messageStoreCompleted with nil notification")
            return
        }
        privateMOC.performBlock() {
            guard let dict = n.userInfo else {
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
                if let msg = self.model.messageByUID(Int(cw.UID()),
                    folderName: self.targetFolderName) {
                    if let flags = cw.flags() {
                        msg.flags = NSNumber.init(short: flags.rawFlagsAsShort())
                        msg.flagsFromServer = msg.flags
                    } else {
                        self.errorOperation(NSLocalizedString(
                            "UID STORE: Response for message without flags",
                            comment: "Technical error"), logMessage:
                            "messageStoreCompleted message without flags, UID: \(cw.UID())")
                    }
                } else {
                    self.errorOperation(NSLocalizedString(
                        "UID STORE: Response for message that can't be found",
                        comment: "Technical error"), logMessage:
                        "messageStoreCompleted message not found, UID: \(cw.UID())")
                }
            }
            self.model.save()
            self.numberOfMessagesSynced += 1
        }
        syncNextMessage()
    }

    public func messageStoreFailed(sync: ImapSync, notification: NSNotification?) {
        addError(Constants.errorMessageStoreFailed(comp))
        markAsFinished()
    }

    public func actionFailed(sync: ImapSync, error: NSError) {
        addError(error)
        markAsFinished()
    }
}