//
//  SyncFlagsToServerOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 31/08/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import CoreData
import MessageModel

protocol SyncFlagsToServerOperationDelegate: class {
    func flagsUploaded(cdMessage: CdMessage)
}

/// Sends (syncs) local changes of Imap flags to server.
public class SyncFlagsToServerOperation: ImapSyncOperation {
    var folderID: NSManagedObjectID
    let folderName: String

    private var currentlyProcessedMessage: CdMessage?
    public var numberOfMessagesSynced: Int {
        return changedMessageIDs.count
    }

    var syncDelegate: SyncFlagsToServerSyncDelegate?
    var changedMessageIDs = [NSManagedObjectID]()
    weak var delegate: SyncFlagsToServerOperationDelegate?

    public init?(parentName: String = #function, errorContainer: ServiceErrorProtocol = ErrorContainer(),
                 imapSyncData: ImapSyncData, folder: CdFolder) {
        guard let moc = folder.managedObjectContext else {
            Log.shared.errorAndCrash(component: #function, errorString: "MO without moc")
            return nil
        }
        var folderName:String? = nil
        var folderID:NSManagedObjectID? = nil
        moc.performAndWait {
            if let fn = folder.name {
                folderName = fn
            } else {
                return
            }
            folderID = folder.objectID
        }
        guard let safeFolderName = folderName, let safeFolderId = folderID else {
            return nil
        }
        self.folderName = safeFolderName
        self.folderID = safeFolderId
        
        super.init(parentName: parentName, errorContainer: errorContainer,
                   imapSyncData: imapSyncData)
    }

    public convenience init?(parentName: String,
                             errorContainer: ServiceErrorProtocol = ErrorContainer(),
                             imapSyncData: ImapSyncData, folderID: NSManagedObjectID) {
        let moc = Record.Context.background
        var folder: CdFolder? = nil;
        moc.performAndWait {
            folder = moc.object(with: folderID) as? CdFolder
        }
        guard let safeFolder = folder else {
            return nil
        }
        
        self.init(parentName: parentName, errorContainer: errorContainer,
                  imapSyncData: imapSyncData, folder: safeFolder)
    }

    public override func main() {
        if !checkImapSync() {
            markAsFinished()
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
            self.waitForBackgroundTasksToFinish()
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
            addError(BackgroundError.CoreDataError.couldNotFindFolder(info: comp))
            waitForBackgroundTasksToFinish()
            return nil
        }
        let messagesToBeSynced = SyncFlagsToServerOperation.messagesToBeSynced(folder: folder,
                                                                               context: context)
        return messagesToBeSynced.first
    }

    func syncNextMessage(context: NSManagedObjectContext) {
        guard !isCancelled else {
            waitForBackgroundTasksToFinish()
            return
        }
        context.performAndWait() { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash(component: #function, errorString: "Lost myself")
                return
            }
            guard let m = me.nextMessageToBeSynced(context: context) else {
                me.waitForBackgroundTasksToFinish()
                return
            }
            me.updateFlags(message: m, context: context)
        }
    }

    func folderOpenCompleted() {
        syncNextMessage(context: privateMOC)
    }
    
    private func
        currentMessageNeedSyncRemoveFlagsToServer(context: NSManagedObjectContext) -> Bool {
        guard let message = currentlyProcessedMessage else {
            return false
        }
        var result = false
        context.performAndWait {
            result = message.storeCommandForUpdateFlags(to: .remove) != nil
        }
        return result
    }

    func updateFlags(message: CdMessage, context: NSManagedObjectContext) {
        currentlyProcessedMessage = message
        updateFlags(to: .add, context: context)
    }

    private func updateFlags(to mode:UpdateFlagsMode, context: NSManagedObjectContext) {
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
        } else if mode == .add && currentMessageNeedSyncRemoveFlagsToServer(context: context) {
            updateFlags(to: .remove, context: context)
        } else {
            syncNextMessage(context: context)
        }
    }

    // MARK: - ImapSyncDelegate (internal)

    func messageStoreCompleted(_ sync: ImapSync, notification: Notification?) {
        let moc = privateMOC
        moc.performAndWait { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash(component: #function, errorString: "I am gone already")
                return
            }
            // flags to add have been synced, but we might need to sync flags to remove also before
            // processing the next message.
            if currentMessageNeedSyncRemoveFlagsToServer(context: moc) {
                updateFlags(to: .remove, context: moc)
                return
            }
            guard let n = notification else {
                handle(error: PantomimeError.missingNotification)
                return
            }
            me.storeMessages(context: moc, notification: n) { [weak self] in
                guard let me = self else {
                    Log.shared.errorAndCrash(component: #function, errorString: "I am gone already")
                    return
                }
                me.syncNextMessage(context: moc)
            }
        }
    }

    func storeMessages(context: NSManagedObjectContext,
                       notification n: Notification, handler: () -> ()) {
        guard let folder = context.object(with: folderID) as? CdFolder else {
            addError(BackgroundError.CoreDataError.couldNotFindFolder(info: comp))
            waitForBackgroundTasksToFinish()
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
            if let cdMsg = CdMessage.first(
                attributes: ["uid": cw.uid(), "parent": folder], in: context) {
                let cwFlags = cw.flags()
                let imap = cdMsg.imapFields(context: context)

                let cdFlags = imap.serverFlags ?? CdImapFlags.create(context: context)
                imap.serverFlags = cdFlags

                cdFlags.update(cwFlags: cwFlags)
                delegate?.flagsUploaded(cdMessage: cdMsg)
                changedMessageIDs.append(cdMsg.objectID)
            } else {
                handle(error: BackgroundError.CoreDataError.couldNotFindMessage(info: nil))
            }
        }
        context.saveAndLogErrors()
        handler()
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

    public override func messageChanged(_ sync: ImapSync, notification: Notification?) {
        // We are informed about a change on the message. As we triggered this change ourself by
        // syncing flag changes to the server, we ignore this information and ...

        // ... do nothing
    }
}
