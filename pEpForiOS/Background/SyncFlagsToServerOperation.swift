//
//  SyncFlagsToServerOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 31/08/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import CoreData
import MessageModel

open class SyncFlagsToServerOperation: ImapSyncOperation {
    var folderID: NSManagedObjectID
    let folderName: String

    fileprivate var currentlyProcessedMessage: CdMessage?
    open var numberOfMessagesSynced = 0

    public init?(parentName: String? = nil, errorContainer: ServiceErrorProtocol = ErrorContainer(),
                 imapSyncData: ImapSyncData, folder: CdFolder) {
        if let fn = folder.name {
            folderName = fn
        } else {
            return nil
        }
        self.folderID = folder.objectID
        super.init(parentName: parentName, errorContainer: errorContainer,
                   imapSyncData: imapSyncData)
    }

    public convenience init?(parentName: String? = nil,
                             errorContainer: ServiceErrorProtocol = ErrorContainer(),
                             imapSyncData: ImapSyncData, folderID: NSManagedObjectID) {
        guard let folder = Record.Context.default.object(with: folderID) as? CdFolder else {
            return nil
        }
        self.init(parentName: parentName, errorContainer: errorContainer,
                  imapSyncData: imapSyncData, folder: folder)
    }

    open override func main() {
        if !shouldRun() {
            return
        }

        if !checkImapSync() {
            return
        }

        privateMOC.perform() {
            self.startSync(context: self.privateMOC)
        }
    }

    func startSync(context: NSManagedObjectContext) {
        imapSyncData.sync?.delegate = self
        // Immediately check for work. If there is none, bail out
        if let _ = nextMessageToBeSynced(context: context) {
            if !self.isCancelled, let sync = imapSyncData.sync {
                if !sync.openMailBox(name: folderName) {
                    syncNextMessage()
                }
            }
        } else {
            self.markAsFinished()
        }
    }

    public static func messagesToBeSynced(
        folder: CdFolder, context: NSManagedObjectContext) -> [CdMessage]? {
        let pFlagsChanged = CdMessage.messagesWithChangedFlagsPredicate(folder: folder)
        return CdMessage.all(
            predicate: pFlagsChanged,
            orderedBy: [NSSortDescriptor(key: "received", ascending: true)], in: context)
            as? [CdMessage]
    }

    func nextMessageToBeSynced(context: NSManagedObjectContext) -> CdMessage? {
        guard let folder = context.object(with: folderID) as? CdFolder else {
            addError(Constants.errorCannotFindFolder(component: comp))
            markAsFinished()
            return nil
        }
        let messagesToBeSynced = SyncFlagsToServerOperation.messagesToBeSynced(folder: folder,
                                                                               context: context)
        return messagesToBeSynced?.first
    }

    func syncNextMessage() {
        currentlyProcessedMessage = nil
        let context = Record.Context.default
        context.perform() {
            guard let m = self.nextMessageToBeSynced(context: context) else {
                self.markAsFinished()
                return
            }
            self.updateFlags(message: m)
        }
    }

    fileprivate func currentMessageNeedSyncRemoveFlagsToServer() -> Bool {
        guard let message = currentlyProcessedMessage else {
            return false
        }
        return message.storeCommandForUpdateFlags(to: .remove) != nil
    }

    func updateFlags(message: CdMessage) {
        currentlyProcessedMessage = message
        updateFlags(to: .add)
    }

    fileprivate func updateFlags(to mode:UpdateFlagsMode) {
        guard let message = currentlyProcessedMessage else {
            Log.shared.errorAndCrash(component:"\(#function)[\(#line)]", errorString: "No message!")
            syncNextMessage()
            return
        }

        var cmd: ImapStoreCommand?

        switch mode {
        case .add:
            cmd = message.storeCommandForUpdateFlags(to: .add)
        case .remove:
            cmd = message.storeCommandForUpdateFlags(to: .remove)
        }

        if cmd != nil {
            if mode == .remove {
                currentlyProcessedMessage = nil
            }
            imapSyncData.sync?.imapStore.send(
                IMAP_UID_STORE, info: cmd!.pantomimeDict as [AnyHashable: Any], string: cmd!.command)
        } else if mode == .add && currentMessageNeedSyncRemoveFlagsToServer(){
            updateFlags(to: .remove)
        } else  {
            syncNextMessage()
        }
    }

    func errorOperation(_ localizedMessage: String, logMessage: String) {
        markAsFinished()
        addError(Constants.errorOperationFailed(comp, errorMessage: localizedMessage))
        Log.error(component: comp, errorString: logMessage)
    }
}

//MARK: - ImapSyncDelegate

extension SyncFlagsToServerOperation: ImapSyncDelegate {
    public func authenticationCompleted(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorIllegalState(comp, stateName: "authenticationCompleted"))
        markAsFinished()
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

    public func folderSyncFailed(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorIllegalState(comp, stateName: "folderSyncFailed"))
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
        // flags to add have been synced, but we might need to sync flags to remove also before
        // processing the next message.
        if currentMessageNeedSyncRemoveFlagsToServer() {
            updateFlags(to: .remove)
            return
        }
        guard let n = notification else {
            errorOperation(NSLocalizedString(
                "UID STORE: Response with missing notification object",comment: "Technical error"),
                           logMessage: "messageStoreCompleted with nil notification")
            return
        }
        privateMOC.performAndWait() {
            self.storeMessages(context: self.privateMOC, notification: n)
        }

        syncNextMessage()
    }

    private func storeMessages(context: NSManagedObjectContext, notification n: Notification) {
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
                attributes: ["uid": cw.uid(), "parent": folder], in: context)
                as? [CdMessage] {
                for m in all {
                    Log.shared.info(component: "\(#function)[\(#line)]",
                        content: "##### \nBefore syncing flags:\nUID: \(m.uid) \n" +
                            "flagsCurrent:\t\(m.imap?.flagsCurrent)" +
                            "\(m.imap?.flagsCurrent.debugString())\n" +
                            "flagsFromServer: \t\(m.imap?.flagsFromServer) " +
                            "\(m.imap?.flagsFromServer.debugString())\n" +
                        "parent?.objectID: \(m.parent?.objectID)")
                }
            }

            if let msg = CdMessage.first(
                attributes: ["uid": cw.uid(), "parent": folder], in: context) {
                let flags = cw.flags()
                let imap = msg.imap ?? CdImapFields.create(context: context)
                msg.imap = imap
                imap.flagsFromServer = flags.rawFlagsAsShort() as Int16
                print("##### \nAfter syncing flags:\nUID: \(msg.uid) \n" +
                    "flagsCurrent:\t\(msg.imap?.flagsCurrent) " +
                    "\(msg.imap?.flagsCurrent.debugString())\n" +
                    "flagsFromServer: \t\(msg.imap?.flagsFromServer)" +
                    "\(msg.imap?.flagsFromServer.debugString())\n" +
                    "parent?.objectID: \(msg.parent?.objectID)")
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
