//
//  SyncMessagesInImapFolderOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 30/11/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import CoreData

import pEpIOSToolbox

///Syncs existing messages in one IMAP fiolder with the servers, e.g., detecting deleted ones.
class SyncMessagesInImapFolderOperation: ImapSyncOperation {
    private var folderID: NSManagedObjectID?
    private let folderToOpen: String
    private let lastUID: UInt
    private let firstUID: UInt

    init(parentName: String = #function,
         context: NSManagedObjectContext? = nil,
         errorContainer: ErrorContainerProtocol = ErrorPropagator(),
         imapConnection: ImapConnectionProtocol,
         folderName: String,
         firstUID: UInt,
         lastUID: UInt) {
        self.folderToOpen = folderName
        self.lastUID = lastUID
        self.firstUID = firstUID
        super.init(parentName: parentName,
                   context: context,
                   errorContainer: errorContainer,
                   imapConnection: imapConnection)
    }

    override func main() {
        if firstUID == 0 || lastUID == 0 {
            waitForBackgroundTasksAndFinish()
            return
        }
        if firstUID > lastUID {
            handle(error: BackgroundError.GeneralError.invalidParameter(info: #function),
                        message: "firstUID should be <= lastUID?")
            return
        }
        if !checkImapConnection() {
            waitForBackgroundTasksAndFinish()
            return
        }
        process()
    }
}

// MARK: - Private

extension SyncMessagesInImapFolderOperation {

    private func process() {
        privateMOC.performAndWait { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }

            guard let cdAccount = me.imapConnection.cdAccount(moc: privateMOC) else {
                me.handle(error: BackgroundError.CoreDataError.couldNotFindAccount(info: nil))
                return
            }
            guard
                let cdFolder = CdFolder.by(name: me.folderToOpen,
                                           account: cdAccount,
                                           context: me.privateMOC)
                else {
                    me.handle(error: BackgroundError.CoreDataError.couldNotFindFolder(info: nil))
                    return
            }
            me.folderID = cdFolder.objectID
        }
        syncDelegate = SyncMessagesInImapFolderOperationDelegate(errorHandler: self)
        imapConnection.delegate = syncDelegate

        resetUidCache()

        guard let _ = folderID else {
            Log.shared.errorAndCrash("No ID")
            waitForBackgroundTasksAndFinish()
            return
        }
        if !imapConnection.openMailBox(name: folderToOpen, updateExistsCount: true) {
            syncMessages()
        }
    }

    private func resetUidCache() {
        imapConnection.resetMatchedUIDs()
    }

    private func syncMessages() {
        do {
            try imapConnection.syncMessages(firstUID: firstUID,
                                            lastUID: lastUID,
                                            updateExistsCount: true)
        } catch {
            addError(error)
            waitForBackgroundTasksAndFinish()
        }
    }

    private func deleteDeletedMails(context: NSManagedObjectContext,
                                    existingUIDs: Set<AnyHashable>) {
        guard let theFolderID = folderID,
            let folder = context.object(with: theFolderID) as? CdFolder else {
                handle(error: BackgroundError.CoreDataError.couldNotFindFolder(info: nil))
                return
        }
        let p1 = CdMessage.PredicateFactory.allMessagesBetweenUids(firstUid: firstUID,
                                                                   lastUid: lastUID)
        let p2 = CdMessage.PredicateFactory.belongingToParentFolder(parentFolder: folder)
        // Do not wipe fake messages that are not on the server (because they are never on the
        // server by definition)
        let p3 = CdMessage.PredicateFactory.isNotFakeMessage()
        // Do not wipe messages that are waiting to be moved to another folder.
        // MoveToFolderOperation is responsible to delete them when done.
        let p4 = CdMessage.PredicateFactory.notMarkedForMoveToFolder()
        let messages = CdMessage.all(
            predicate: NSCompoundPredicate(andPredicateWithSubpredicates: [p1, p2, p3, p4]),
            in: context)
            as? [CdMessage] ?? []
        for msg in messages {
            if !existingUIDs.contains(NSNumber(value: msg.uid)) {
                msg.delete(context: context)
            }
        }
        context.saveAndLogErrors()
    }
}

// MARK: - Callback Handler

extension SyncMessagesInImapFolderOperation {

    fileprivate func handleFolderSyncCompleted(_ imapConnection: ImapConnectionProtocol) {
        backgroundQueue.addOperation { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            me.privateMOC.performAndWait {
                // delete locally whatever was not mentioned in our big sync
                if let existingUIDs = imapConnection.existingUIDs() {
                    me.deleteDeletedMails(context: me.privateMOC, existingUIDs:existingUIDs)
                }
                me.waitForBackgroundTasksAndFinish()
            }
        }
    }

    fileprivate func handleFolderOpenCompleted(_ imapConnection: ImapConnectionProtocol, notification: Notification?) {
        syncMessages()
    }
}

// MARK: - ImapSyncDelegate (actual delegate)

class SyncMessagesInImapFolderOperationDelegate: DefaultImapConnectionDelegate {
    override public func folderSyncCompleted(_ imapConnection: ImapConnectionProtocol, notification: Notification?) {
        guard let op = (errorHandler as? SyncMessagesInImapFolderOperation) else {
            Log.shared.errorAndCrash("No OP")
            return
        }
        op.handleFolderSyncCompleted(imapConnection)
    }

    override public  func folderOpenCompleted(_ imapConnection: ImapConnectionProtocol, notification: Notification?) {
        guard let op = (errorHandler as? SyncMessagesInImapFolderOperation) else {
            Log.shared.errorAndCrash("No OP")
            return
        }
        op.handleFolderOpenCompleted(imapConnection, notification: notification)
    }
}
