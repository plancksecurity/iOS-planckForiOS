//
//  SyncFlagsToServerOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 31/08/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import CoreData

import MessageModel

open class SyncFlagsToServerOperation: ConcurrentBaseOperation {
    let connectInfo: EmailConnectInfo
    let connectionManager: ImapConnectionManagerProtocol

    var folderID: NSManagedObjectID
    let folderName: String

    var imapSync: ImapSync!

    open var numberOfMessagesSynced = 0

    public init?(connectInfo: EmailConnectInfo, folder: CdFolder,
                connectionManager: ImapConnectionManagerProtocol) {
        if let fn = folder.name {
            folderName = fn
        } else {
            return nil
        }
        self.connectInfo = connectInfo
        self.folderID = folder.objectID
        self.connectionManager = connectionManager
    }

    open override func main() {
        imapSync = connectionManager.imapConnection(connectInfo: connectInfo)
        if !checkImapSync(sync: imapSync) {
            return
        }

        privateMOC.perform() {
            self.startSync(context: self.privateMOC)
        }
    }

    func startSync(context: NSManagedObjectContext) {
        // Immediately check for work. If there is none, bail out
        if let _ = nextMessageToBeSynced(context: context) {
            self.imapSync.delegate = self
            self.imapSync.start()
        } else {
            self.markAsFinished()
        }
    }

    public static func messagesToBeSynced(
        folder: CdFolder, context: NSManagedObjectContext) -> [CdMessage]? {
        let pFlagsChanged = CdMessage.messagesWithChangedFlagsPredicate(folder: folder)
        return CdMessage.all(
            with: pFlagsChanged,
            orderedBy: [NSSortDescriptor(key: "received", ascending: true)], in: context)
            as? [CdMessage]
    }

    func nextMessageToBeSynced(context: NSManagedObjectContext) -> CdMessage? {
        guard let folder = context.object(with: folderID) as? CdFolder else {
            addError(Constants.errorCannotFindFolder(component: comp))
            markAsFinished()
            return nil
        }
        return SyncFlagsToServerOperation.messagesToBeSynced(
            folder: folder, context: context)?.first
    }

    func syncNextMessage() {
        let context = Record.Context.default
        context.perform() {
            guard let m = self.nextMessageToBeSynced(context: context) else {
                self.markAsFinished()
                return
            }
            self.updateFlags(message: m)
        }
    }

    func updateFlags(message: CdMessage) {
        if let (cmd, dict) = message.storeCommandForUpdate() {
            imapSync.imapStore.send(
                IMAP_UID_STORE, info: dict as [AnyHashable: Any], string: cmd)
        } else {
            addError(Constants.errorNoFlags(component: comp))
            markAsFinished()
        }
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
            sync.openMailBox(name: folderName)
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

    public func folderSyncCompleted(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorIllegalState(comp, stateName: "folderSyncCompleted"))
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
        privateMOC.performAndWait() {
            self.storeMessages(context: self.privateMOC, notification: n)
        }

        syncNextMessage()
    }

    func storeMessages(context: NSManagedObjectContext, notification n: Notification) {
        guard let folder = context.object(with: folderID) as? CdFolder else {
            addError(Constants.errorCannotFindFolder(component: comp))
            markAsFinished()
            return
        }

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
            if let all = CdMessage.all(
                with: ["uid": cw.uid(), "parent": folder], in: context)
                as? [CdMessage] {
                for m in all {
                    print("\(m.uid) \(m.imap?.flagsCurrent) \(m.imap?.flagsFromServer) \(m.parent?.objectID)")
                }
            }

            if let msg = CdMessage.first(
                with: ["uid": cw.uid(), "parent": folder], in: context) {
                let flags = cw.flags()
                let imap = msg.imap ?? CdImapFields.createWithDefaults(in: context)
                msg.imap = imap
                imap.flagsFromServer = flags.rawFlagsAsShort() as Int16
                imap.flagsCurrent = imap.flagsFromServer
            } else {
                self.errorOperation(NSLocalizedString(
                    "UID STORE: Response for message that can't be found",
                    comment: "Technical error"), logMessage:
                    "messageStoreCompleted message not found, UID: \(cw.uid())")
            }
        }
        Record.saveAndWait(context: context)
        self.numberOfMessagesSynced += 1
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
