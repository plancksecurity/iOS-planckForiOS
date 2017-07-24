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

    var syncDelegate: SyncFlagsToServerSyncDelegate?

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
        syncDelegate = SyncFlagsToServerSyncDelegate(errorHandler: self)
        imapSyncData.sync?.delegate = syncDelegate
        // Immediately check for work. If there is none, bail out
        if let _ = nextMessageToBeSynced(context: context) {
            if !self.isCancelled, let sync = imapSyncData.sync {
                if !sync.openMailBox(name: folderName) {
                    syncNextMessage(context: context)
                }
            }
        } else {
            self.markAsFinished()
        }
    }

    public static func messagesToBeSynced(
        folder: CdFolder, context: NSManagedObjectContext) -> [CdMessage] {
        let pFlagsChanged = CdMessage.messagesWithChangedFlagsPredicate(folder: folder)
        return CdMessage.all(
            predicate: pFlagsChanged,
            orderedBy: [NSSortDescriptor(key: "received", ascending: true)], in: context)
            as? [CdMessage] ?? []
    }

    func nextMessageToBeSynced(context: NSManagedObjectContext) -> CdMessage? {
        guard let folder = context.object(with: folderID) as? CdFolder else {
            addError(Constants.errorCannotFindFolder(component: comp))
            markAsFinished()
            return nil
        }
        let messagesToBeSynced = SyncFlagsToServerOperation.messagesToBeSynced(folder: folder,
                                                                               context: context)
        return messagesToBeSynced.first
    }

    func syncNextMessage(context: NSManagedObjectContext) {
        context.perform() {
            guard let m = self.nextMessageToBeSynced(context: context) else {
                self.markAsFinished()
                return
            }
            self.updateFlags(message: m, context: context)
        }
    }

    func folderOpenCompleted() {
        syncNextMessage(context: privateMOC)
    }

    fileprivate func currentMessageNeedSyncRemoveFlagsToServer() -> Bool {
        guard let message = currentlyProcessedMessage else {
            return false
        }
        return message.storeCommandForUpdateFlags(to: .remove) != nil
    }

    func updateFlags(message: CdMessage, context: NSManagedObjectContext) {
        currentlyProcessedMessage = message
        updateFlags(to: .add, context: context)
    }

    fileprivate func updateFlags(to mode:UpdateFlagsMode, context: NSManagedObjectContext) {
        guard let message = currentlyProcessedMessage else {
            Log.shared.errorAndCrash(component:"\(#function)[\(#line)]", errorString: "No message!")
            syncNextMessage(context: context)
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
            if let info = cmd?.pantomimeDict, let string = cmd?.command {
                imapSyncData.sync?.imapStore.send(IMAP_UID_STORE,
                                                  info: info,
                                                  string: string)
            } else {
                Log.shared.errorAndCrash(component: comp, errorString: "No IMAP store command")
            }
        } else if mode == .add && currentMessageNeedSyncRemoveFlagsToServer() {
            updateFlags(to: .remove, context: context)
        } else {
            syncNextMessage(context: context)
        }
    }

    // MARK: - ImapSyncDelegate (internal)

    func messageStoreCompleted(_ sync: ImapSync, notification: Notification?) {
        // flags to add have been synced, but we might need to sync flags to remove also before
        // processing the next message.
        if currentMessageNeedSyncRemoveFlagsToServer() {
            updateFlags(to: .remove, context: privateMOC)
            return
        }
        guard let n = notification else {
            handle(error: PantomimeError.missingNotification)
            return
        }
        let context = privateMOC
        context.perform() { [weak self] in
            self?.storeMessages(context: context, notification: n) { [weak self] in
                    self?.syncNextMessage(context: context)
            }
        }
    }

    func storeMessages(context: NSManagedObjectContext,
                       notification n: Notification, handler: () -> ()) {
        guard let folder = context.object(with: folderID) as? CdFolder else {
            addError(Constants.errorCannotFindFolder(component: comp))
            markAsFinished()
            handler()
            return
        }

        guard let dict = (n as NSNotification).userInfo else {
            handle(error: PantomimeError.missingUserInfo)
            handler()
            return
        }
        guard let cwMessages = dict[PantomimeMessagesKey] as? [CWIMAPMessage] else {
            handle(error: PantomimeError.missingMessages)
            handler()
            return
        }

        for cw in cwMessages {
            if let msg = CdMessage.first(
                attributes: ["uid": cw.uid(), "parent": folder], in: context) {
                let cwFlags = cw.flags()
                let imap = msg.imapFields(context: context)

                let cdFlags = imap.serverFlags ?? CdImapFlags.create(context: context)
                imap.serverFlags = cdFlags

                cdFlags.update(cwFlags: cwFlags)
            } else {
                handle(error: CoreDataError.couldNotFindMessage)
            }
        }
        context.saveAndLogErrors()
        self.numberOfMessagesSynced += 1
        handler()
    }

    override func markAsFinished() {
        syncDelegate = nil
        super.markAsFinished()
    }
}

// MARK: - ImapSyncDelegate (actual delegate)

class SyncFlagsToServerSyncDelegate: DefaultImapSyncDelegate {
    override func messageStoreCompleted(_ sync: ImapSync, notification: Notification?) {
        (errorHandler as? SyncFlagsToServerOperation)?.messageStoreCompleted(
            sync, notification: notification)
    }

    public override func folderOpenCompleted(_ sync: ImapSync, notification: Notification?) {
        (errorHandler as? SyncFlagsToServerOperation)?.folderOpenCompleted()
    }
}
