//
//  SyncMessagesOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 30/11/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit
import CoreData

import MessageModel

/**
 Syncs existing messages with the servers, e.g., detecting deleted ones.
 */
public class SyncMessagesOperation: ImapSyncOperation {
    var folderID: NSManagedObjectID?
    let folderToOpen: String
    let lastUID: UInt
    let firstUID: UInt
    var syncDelegate: SyncMessagesSyncDelegate?

    private let logger = Logger(category: Logger.backend)

    init(parentName: String = #function,
         errorContainer: ServiceErrorProtocol = ErrorContainer(),
         imapSyncData: ImapSyncData,
         folderName: String,
         firstUID: UInt,
         lastUID: UInt) {
        self.folderToOpen = folderName
        self.lastUID = lastUID
        self.firstUID = firstUID
        super.init(parentName: parentName, errorContainer: errorContainer,
                   imapSyncData: imapSyncData)
    }

    convenience init?(parentName: String,
                      errorContainer: ServiceErrorProtocol = ErrorContainer(),
                      imapSyncData: ImapSyncData,
                      folder: CdFolder) {
        guard let folderName = folder.name else {
            return nil
        }
        self.init(parentName: parentName, errorContainer: errorContainer,
                  imapSyncData: imapSyncData, folderName: folderName,
                  firstUID: folder.firstUID(), lastUID: folder.lastUID())
        folderID = folder.objectID
    }

    override public func main() {
        if firstUID == 0 || lastUID == 0 {
            markAsFinished()
            return
        }
        if firstUID > lastUID {
            handleError(BackgroundError.GeneralError.invalidParameter(info: #function),
                        message: "firstUID should be <= lastUID?")
            return
        }
        if !checkImapSync() {
            markAsFinished()
            return
        }
        let context = privateMOC
        context.perform() {
            self.process(context: context)
        }
    }

    private func process(context: NSManagedObjectContext) {
        guard
            let accountId = imapSyncData.connectInfo.accountObjectID,
            let cdAccount = context.object(with: accountId) as? CdAccount else {
                handleError(BackgroundError.CoreDataError.couldNotFindAccount(info: nil))
                return
        }
        guard
            let cdFolder = CdFolder.by(name: folderToOpen, account: cdAccount)
            else {
                handleError(BackgroundError.CoreDataError.couldNotFindFolder(info: nil))
                return
        }
        folderID = cdFolder.objectID

        let folderBuilder = ImapFolderBuilder(accountID: accountId,
                                              backgroundQueue: self.backgroundQueue)
        syncDelegate = SyncMessagesSyncDelegate(errorHandler: self)
        self.imapSyncData.sync?.delegate = syncDelegate
        self.imapSyncData.sync?.folderBuilder = folderBuilder

        guard let sync = self.imapSyncData.sync else {
            logger.errorAndCrash("No sync")
            handle(error: BackgroundError.GeneralError.illegalState(info: "No sync"))
            return
        }

        resetUidCache()
        if !sync.openMailBox(name: self.folderToOpen, updateExistsCount: true) {
            self.syncMessages(sync)
        }
    }

    private func resetUidCache() {
        guard let sync = self.imapSyncData.sync else {
            logger.errorAndCrash("No sync")
            handle(error: BackgroundError.GeneralError.illegalState(info: "No sync"))
            return
        }
        sync.imapState.currentFolder?.resetMatchedUIDs()
    }

    private func syncMessages(_ sync: ImapSync) {
        do {
            try sync.syncMessages(firstUID: firstUID, lastUID: lastUID, updateExistsCount: true)
        } catch {
            addError(error)
            waitForBackgroundTasksToFinish()
        }
    }

    private func deleteDeletedMails(context: NSManagedObjectContext, existingUIDs: Set<AnyHashable>) {
        guard
            let theFolderID = folderID,
            let folder = context.object(with: theFolderID) as? CdFolder else {
                handleError(BackgroundError.CoreDataError.couldNotFindFolder(info: nil))
                return
        }
        let p1 = NSPredicate(format: "uid >= %d and uid <= %d", firstUID, lastUID)
        let p2 = NSPredicate(format: "parent = %@", folder)
        let messages = CdMessage.all(
            predicate: NSCompoundPredicate(
                andPredicateWithSubpredicates: [p1, p2])) as? [CdMessage] ?? []
        for msg in messages {
            if !existingUIDs.contains(NSNumber(value: msg.uid)) {
                msg.deleteAndInformDelegate(context: context)
            }
        }
    }

    // MARK: - ImapSyncDelegate (internal)

    fileprivate func folderSyncCompleted(_ sync: ImapSync, notification: Notification?) {
        // delete locally whatever was not mentioned in our big sync
        if let folder = sync.imapState.currentFolder {
            let existingUIDs = folder.existingUIDs()
            let context = privateMOC
            context.performAndWait() {
                self.deleteDeletedMails(context: context, existingUIDs:existingUIDs)
            }
        }
        markAsFinished()
    }

    fileprivate func folderOpenCompleted(_ sync: ImapSync, notification: Notification?) {
        syncMessages(sync)
    }

    override func markAsFinished() {
        syncDelegate = nil
        super.markAsFinished()
    }
}

// MARK: - ImapSyncDelegate (actual delegate)

class SyncMessagesSyncDelegate: DefaultImapSyncDelegate {
    private let logger = Logger(category: Logger.backend)

    override public func folderSyncCompleted(_ sync: ImapSync, notification: Notification?) {
        guard let _ = errorHandler else {
            logger.errorAndCrash("We must have an errorHandler here")
            return
        }
        (errorHandler as? SyncMessagesOperation)?.folderSyncCompleted(
            sync, notification: notification)
    }

    override public func messageChanged(_ sync: ImapSync, notification: Notification?) {
        // The update of the flags is already handled by `PersistentFolder`.
    }

    override public  func folderOpenCompleted(_ sync: ImapSync, notification: Notification?) {
        guard let _ = errorHandler else {
            logger.errorAndCrash("We must have an errorHandler here")
            return
        }
        (errorHandler as? SyncMessagesOperation)?.folderOpenCompleted(
            sync, notification: notification)
    }
}
