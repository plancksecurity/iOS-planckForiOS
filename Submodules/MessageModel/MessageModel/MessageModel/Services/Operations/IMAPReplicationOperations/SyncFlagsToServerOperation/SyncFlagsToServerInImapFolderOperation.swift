//
//  SyncFlagsToServerInImapFolderOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 31/08/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import CoreData

import PantomimeFramework
import pEpIOSToolbox

/// Sends (syncs) local changes of Imap flags to server.
class SyncFlagsToServerInImapFolderOperation: ImapSyncOperation {
    private let folderID: NSManagedObjectID

    private lazy var folderName: String? = {
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

    // Used for Tests only. hould be refactored out.
    var numberOfMessagesSynced: Int {
        return changedMessageIDs.count
    }

    // Used for Tests only. hould be refactored out.
    var changedMessageIDs = [NSManagedObjectID]()

    init(parentName: String = #function,
         context: NSManagedObjectContext? = nil,
         errorContainer: ErrorContainerProtocol = ErrorPropagator(),
         imapConnection: ImapConnectionProtocol,
         folderID: NSManagedObjectID) {
        self.folderID = folderID
        super.init(parentName: parentName,
                   context: context,
                   errorContainer: errorContainer,
                   imapConnection: imapConnection)
    }

    public override func main() {
        if !checkImapSync() {
            waitForBackgroundTasksAndFinish()
            return
        }
        privateMOC.perform() {
            self.startSync()
        }
    }

    private func startSync() {
        guard let folderName = folderName else {
            Log.shared.errorAndCrash("No folder name")
            waitForBackgroundTasksAndFinish()
            return
        }
        syncDelegate = SyncFlagsToServerInImapFolderOperationDelegate(errorHandler: self)
        imapConnection.delegate = syncDelegate
        // Immediately check for work. If there is none, bail out
        guard
            let _ = nextMessageToBeSynced(),
            !isCancelled
            else {
                waitForBackgroundTasksAndFinish()
                return
        }

        if !imapConnection.openMailBox(name: folderName, updateExistsCount: false) {
            syncNextMessage()
        }
    }

    private func nextMessageToBeSynced() -> CdMessage? {
        guard let folder = privateMOC.object(with: folderID) as? CdFolder else {
            addError(BackgroundError.CoreDataError.couldNotFindFolder(info: comp))
            waitForBackgroundTasksAndFinish()
            return nil
        }

        let nextMessages = SyncFlagsToServerInImapFolderOperation.messagesToBeSynced(folder: folder,
                                                                         context: privateMOC)
        return nextMessages.first
    }

    private func syncNextMessage() {
        let op = BlockOperation() { [weak self] in
            guard let me = self else {
                Log.shared.lostMySelf()
                return
            }

            guard !me.isCancelled else {
                me.waitForBackgroundTasksAndFinish()
                return
            }
            me.privateMOC.performAndWait {
                guard let m = me.nextMessageToBeSynced() else {
                    me.waitForBackgroundTasksAndFinish()
                    return
                }
                me.updateFlags(message: m)
            }
        }
        backgroundQueue.addOperation(op)
    }

    private func currentMessageNeedSyncRemoveFlagsToServer() -> Bool {
        guard let message = currentlyProcessedMessage else {
            return false
        }
        return message.storeCommandForUpdateFlags(to: .remove) != nil
    }

    private func updateFlags(message: CdMessage) {
        currentlyProcessedMessage = message
        updateFlags(to: .add)
    }

    private func updateFlags(to mode:UpdateFlagsMode) {
        guard let message = currentlyProcessedMessage else {
            Log.shared.errorAndCrash("No message")
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
                imapConnection.store(info: info, command: string)
            } else {
                Log.shared.errorAndCrash("No IMAP store command")
                waitForBackgroundTasksAndFinish()
            }
        } else if mode == .add && currentMessageNeedSyncRemoveFlagsToServer() {
            updateFlags(to: .remove)
        } else {
            syncNextMessage()
        }
    }

    private func storeMessages(notification n: Notification) {
        guard let folder = privateMOC.object(with: folderID) as? CdFolder else {
            handle(error: BackgroundError.CoreDataError.couldNotFindFolder(info: comp))
            return
        }

        guard let dict = (n as NSNotification).userInfo else {
            handle(error: PantomimeError.missingUserInfo)
            return
        }
        guard let cwMessages = dict[PantomimeMessagesKey] as? [CWIMAPMessage] else {
            handle(error: PantomimeError.missingMessages)
            return
        }

        for cwMsg in cwMessages {
            if let cdMsg = CdMessage.first(attributes: ["uid": cwMsg.uid(), "parent": folder],
                                           in: privateMOC) {
                let cwFlags = cwMsg.flags()
                let imap = cdMsg.imapFields(context: privateMOC)

                imap.serverFlags?.update(cwFlags: cwFlags)
                cdMsg.imap = imap
                changedMessageIDs.append(cdMsg.objectID)
            } else {
                handle(error: BackgroundError.CoreDataError.couldNotFindMessage(info: nil))
            }
        }

        privateMOC.saveAndLogErrors()
    }

    // MARK: - Static

    public static func messagesToBeSynced(folder: CdFolder,
                                          context: NSManagedObjectContext) -> [CdMessage] {
        let pFlagsChanged = CdMessage.PredicateFactory.changedFlags(folder: folder)
        return CdMessage.all(predicate: pFlagsChanged, in: context) as? [CdMessage] ?? []
    }

    // MARK: - Callback Handler

    fileprivate func handleMessageStoreCompleted(notification: Notification?) {
        backgroundQueue.addOperation { [weak self] in
            guard let me = self else {
                Log.shared.lostMySelf()
                return
            }
            me.privateMOC.performAndWait {
                // flags to add have been synced, but we might need to sync flags to remove also before
                // processing the next message.
                if me.currentMessageNeedSyncRemoveFlagsToServer() {
                    me.updateFlags(to: .remove)
                    return
                }
                guard let n = notification else {
                    me.handle(error: PantomimeError.missingNotification)
                    return
                }
                me.storeMessages(notification: n)
                if me.isCancelled {
                    me.waitForBackgroundTasksAndFinish()
                    return
                }
                me.syncNextMessage()
            }
        }
    }

    fileprivate func handleFolderOpenCompleted() {
        syncNextMessage()
    }
}

// MARK: - ImapSyncDelegate (actual delegate)

class SyncFlagsToServerInImapFolderOperationDelegate: DefaultImapConnectionDelegate {
    override func messageStoreCompleted(_ imapConnection: ImapConnectionProtocol, notification: Notification?) {
        guard let op = (errorHandler as? SyncFlagsToServerInImapFolderOperation) else {
            Log.shared.errorAndCrash("lost active OP")
            return
        }
        op.handleMessageStoreCompleted(notification: notification)
    }

    public override func folderOpenCompleted(_ imapConnection: ImapConnectionProtocol, notification: Notification?) {
        guard let op = (errorHandler as? SyncFlagsToServerInImapFolderOperation) else {
            Log.shared.errorAndCrash("lost active OP")
            return
        }
        op.handleFolderOpenCompleted()
    }

    override func messageStoreFailed(_ imapConection: ImapConnectionProtocol, notification: Notification?) {
        guard let op = (errorHandler as? SyncFlagsToServerInImapFolderOperation) else {
            Log.shared.errorAndCrash("lost active OP")
            return
        }
        op.handle(error: BackgroundError.GeneralError.operationFailed(info: notification?.userInfo?.description))
    }
}
