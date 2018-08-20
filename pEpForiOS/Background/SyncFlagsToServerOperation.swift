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

    lazy var folderName: String? = {
        var result: String? = nil
        privateMOC.performAndWait {
            guard
                let folder = privateMOC.object(with: folderID) as? CdFolder,
                let folderName = folder.name else {
                    return
            }
            result = folderName
        }
        return result
    }()

    private var currentlyProcessedMessage: CdMessage?
    var numberOfMessagesSynced: Int {
        return changedMessageIDs.count
    }

    var syncDelegate: SyncFlagsToServerSyncDelegate?
    var changedMessageIDs = [NSManagedObjectID]()
    weak var delegate: SyncFlagsToServerOperationDelegate?

    init(parentName: String = #function, errorContainer: ServiceErrorProtocol = ErrorContainer(),
         imapSyncData: ImapSyncData,  folderID: NSManagedObjectID) {
        self.folderID = folderID
        super.init(parentName: parentName, errorContainer: errorContainer,
                   imapSyncData: imapSyncData)
    }

    public override func main() {
        if !checkImapSync() {
            markAsFinished()
            return
        }
        privateMOC.perform() {
            self.startSync()
        }
    }

    func startSync() {
        guard let folderName = folderName else {
            Log.shared.errorAndCrash(component: #function, errorString: "No folderName")
            waitForBackgroundTasksToFinish()
            return
        }
        syncDelegate = SyncFlagsToServerSyncDelegate(errorHandler: self)
        imapSyncData.sync?.delegate = syncDelegate
        // Immediately check for work. If there is none, bail out
        if let _ = nextMessageToBeSynced() {
            if !self.isCancelled, let sync = imapSyncData.sync {
                if !sync.openMailBox(name: folderName) {
                    syncNextMessage()
                }
            }
        } else {
            self.waitForBackgroundTasksToFinish()
        }
    }

    public static func messagesToBeSynced(folder: CdFolder,
                                          context: NSManagedObjectContext) -> [CdMessage] {
        let pFlagsChanged = CdMessage.messagesWithChangedFlagsPredicate(folder: folder)
        return CdMessage.all(
            predicate: pFlagsChanged,
            orderedBy: [NSSortDescriptor(key: "received", ascending: true)], in: context)
            as? [CdMessage] ?? []
    }

    func nextMessageToBeSynced() -> CdMessage? {
        guard let folder = privateMOC.object(with: folderID) as? CdFolder else {
            addError(BackgroundError.CoreDataError.couldNotFindFolder(info: comp))
            waitForBackgroundTasksToFinish()
            return nil
        }
        let messagesToBeSynced = SyncFlagsToServerOperation.messagesToBeSynced(folder: folder,
                                                                               context: privateMOC)
        return messagesToBeSynced.first
    }

    func syncNextMessage() {
        let op = BlockOperation() { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash(component: #function, errorString: "Lost myself")
                return
            }

            guard !me.isCancelled else {
                me.waitForBackgroundTasksToFinish()
                return
            }
            me.privateMOC.perform() {
                guard let m = me.nextMessageToBeSynced() else {
                    me.waitForBackgroundTasksToFinish()
                    return
                }
                me.updateFlags(message: m)
            }
        }
        backgroundQueue.addOperation(op)
    }

    func folderOpenCompleted() {
        syncNextMessage()
    }

    private func currentMessageNeedSyncRemoveFlagsToServer() -> Bool {
        guard let message = currentlyProcessedMessage else {
            return false
        }
        var result = false
        privateMOC.performAndWait {
            result = message.storeCommandForUpdateFlags(to: .remove) != nil
        }
        return result
    }

    func updateFlags(message: CdMessage) {
        currentlyProcessedMessage = message
        updateFlags(to: .add)
    }

    private func updateFlags(to mode:UpdateFlagsMode) {
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
            if let info = cmd?.pantomimeDict, let string = cmd?.command {
                imapSyncData.sync?.imapStore.send(IMAP_UID_STORE,
                                                  info: info,
                                                  string: string)
            } else {
                Log.shared.errorAndCrash(component: comp, errorString: "No IMAP store command")
            }
        } else if mode == .add && currentMessageNeedSyncRemoveFlagsToServer() {
            updateFlags(to: .remove)
        } else {
            syncNextMessage()
        }
    }

    // MARK: - ImapSyncDelegate (internal)

    func messageStoreCompleted(_ sync: ImapSync, notification: Notification?) {
        privateMOC.performAndWait { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash(component: #function, errorString: "I am gone already")
                return
            }
            // flags to add have been synced, but we might need to sync flags to remove also before
            // processing the next message.
            if currentMessageNeedSyncRemoveFlagsToServer() {
                updateFlags(to: .remove)
                return
            }
            guard let n = notification else {
                handle(error: PantomimeError.missingNotification)
                return
            }
            me.storeMessages(notification: n) { [weak self] in
                guard let me = self else {
                    Log.shared.errorAndCrash(component: #function, errorString: "I am gone already")
                    return
                }
                me.syncNextMessage()
            }
        }
    }

    func storeMessages(notification n: Notification, handler: () -> ()) {
        let moc = privateMOC
        guard let folder = moc.object(with: folderID) as? CdFolder else {
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
                attributes: ["uid": cw.uid(), "parent": folder]) {
                let cwFlags = cw.flags()
                let imap = cdMsg.imapFields(context: privateMOC)

                let cdFlags = imap.serverFlags ?? CdImapFlags.create(context: moc)
                imap.serverFlags = cdFlags

                cdFlags.update(cwFlags: cwFlags)
                delegate?.flagsUploaded(cdMessage: cdMsg)
                changedMessageIDs.append(cdMsg.objectID)
            } else {
                handle(error: BackgroundError.CoreDataError.couldNotFindMessage(info: nil))
            }
        }
        moc.saveAndLogErrors()
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
