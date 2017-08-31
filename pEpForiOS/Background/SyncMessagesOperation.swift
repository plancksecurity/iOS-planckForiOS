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


    //BUFF:
    //    var syncDelegate: SyncMessagesSyncDelegate?
    var _syncDelegate: SyncMessagesSyncDelegate?
    weak var syncDelegate: SyncMessagesSyncDelegate? {
        get {
            return _syncDelegate
        }
        set {
            _syncDelegate = newValue
            if newValue == nil {
                if _syncDelegate != nil {
                    print("BUFF: SyncMessagesOperation. syncDelegate: \(_syncDelegate!.self) has been set to nil)")
                }
            } else {
                print("BUFF: SyncMessagesOperation syncDelegate has been set to \(newValue!)")
            }
        }
    }
    //FFUB

    public init(parentName: String = #function, errorContainer: ServiceErrorProtocol = ErrorContainer(),
                imapSyncData: ImapSyncData, folderName: String, firstUID: UInt, lastUID: UInt) {
        self.folderToOpen = folderName
        self.lastUID = lastUID
        self.firstUID = firstUID
        super.init(parentName: parentName, errorContainer: errorContainer,
                   imapSyncData: imapSyncData)
    }

    public convenience init?(parentName: String,
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

    public override func shouldRun() -> Bool {
        if !super.shouldRun() {
            return false
        }
        if firstUID == 0 || lastUID == 0 {
            markAsFinished()
            return false
        }
        if firstUID > lastUID {
            handleError(OperationError.illegalParameter, message: "firstUID should be <= lastUID?")
            return false
        }
        return true
    }

    override public func main() {
        if !shouldRun() {
            return
        }

        if !checkImapSync() {
            return
        }

        let context = Record.Context.default
        context.perform() {
            self.process(context: context)
        }
    }

    func process(context: NSManagedObjectContext) {
        guard
            let cdAccount = context.object(
                with: imapSyncData.connectInfo.accountObjectID) as? CdAccount
            else {
                handleError(CoreDataError.couldNotFindAccount)
                return
        }
        guard
            let cdFolder = CdFolder.by(name: folderToOpen, account: cdAccount)
            else {
                handleError(CoreDataError.couldNotFindFolder)
                return
        }
        folderID = cdFolder.objectID

        let folderBuilder = ImapFolderBuilder(
            accountID: self.imapSyncData.connectInfo.accountObjectID,
            backgroundQueue: self.backgroundQueue)
        syncDelegate = SyncMessagesSyncDelegate(errorHandler: self)
        self.imapSyncData.sync?.delegate = syncDelegate
        self.imapSyncData.sync?.folderBuilder = folderBuilder

        if let sync = self.imapSyncData.sync {
            if !sync.openMailBox(name: self.folderToOpen) {
                sync.imapState.currentFolder?.resetMatchedUIDs()
                self.syncMessages(sync)
            }
        }
    }

    func syncMessages(_ sync: ImapSync) {
        do {
            try sync.syncMessages(firstUID: firstUID, lastUID: lastUID)
        } catch let err as NSError {
            addError(err)
            waitForBackgroundTasksToFinish()
        }
    }

    func deleteDeletedMails(context: NSManagedObjectContext, existingUIDs: Set<AnyHashable>) {
        guard
            let theFolderID = folderID,
            let folder = context.object(with: theFolderID) as? CdFolder else {
                handleError(CoreDataError.couldNotFindFolder)
                return
        }
        let p1 = NSPredicate(format: "uid >= %d and uid <= %d", firstUID, lastUID)
        let p2 = NSPredicate(format: "parent = %@", folder)
        let messages = CdMessage.all(
            predicate: NSCompoundPredicate(
                andPredicateWithSubpredicates: [p1, p2])) as? [CdMessage] ?? []
        for msg in messages {
            if !existingUIDs.contains(NSNumber(value: msg.uid)) {
                Log.info(component: comp,
                         content: "removing message UID \(msg.uid) messageID \(String(describing: msg.uuid))")
                msg.deleteAndInformDelegate(context: context)
            }
        }
    }

    // MARK: - ImapSyncDelegate (internal)

    func folderSyncCompleted(_ sync: ImapSync, notification: Notification?) {
        // delete locally whatever was not mentioned in our big sync
        if let folder = sync.imapState.currentFolder {
            let existingUIDs = folder.existingUIDs()
            let context = Record.Context.background
            context.performAndWait() {
                self.deleteDeletedMails(context: context, existingUIDs:existingUIDs)
            }
        }
        markAsFinished()
    }

    func folderOpenCompleted(_ sync: ImapSync, notification: Notification?) {
        syncMessages(sync)
    }

    override func markAsFinished() {
        print("//BUFF: SyncMessagesOperation called markAsFinished()") //BUFF:
        syncDelegate = nil
        super.markAsFinished()
    }

    //BUFF:
    deinit {
        print("Buff: deinit: \(type(of:self))")
    }
    //FFUB
}

// MARK: - ImapSyncDelegate (actual delegate)

class SyncMessagesSyncDelegate: DefaultImapSyncDelegate {
    override public func folderSyncCompleted(_ sync: ImapSync, notification: Notification?) {
        guard let _ = errorHandler else {
            Log.shared.errorAndCrash(component: #function,
                                     errorString: "We must have an errorHandler here!")
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
            Log.shared.errorAndCrash(component: #function,
                                     errorString: "We must have an errorHandler here!")
            return
        }
        (errorHandler as? SyncMessagesOperation)?.folderOpenCompleted(
            sync, notification: notification)
    }

    //BUFF:
    deinit {
        print("Buff: deinit: \(type(of:self))")
    }
    //FFUB
}
