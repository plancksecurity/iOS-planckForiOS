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

open class SyncMessagesOperation: ImapSyncOperation {
    let folderID: NSManagedObjectID
    let folderToOpen: String
    let lastUID: UInt
    let firstUID: UInt
    var lastSeenUID: UInt?

    public init(parentName: String? = nil, errorContainer: ServiceErrorProtocol = ErrorContainer(),
                imapSyncData: ImapSyncData, folderID: NSManagedObjectID,
                folderName: String, firstUID: UInt, lastUID: UInt) {
        self.folderID = folderID
        self.folderToOpen = folderName
        self.lastUID = lastUID
        self.firstUID = firstUID
        super.init(parentName: parentName, errorContainer: errorContainer,
                   imapSyncData: imapSyncData)
    }

    public convenience init?(parentName: String? = nil,
                             errorContainer: ServiceErrorProtocol = ErrorContainer(),
                             imapSyncData: ImapSyncData,
                             folder: CdFolder, firstUID: UInt, lastUID: UInt) {
        guard let folderName = folder.name else {
            return nil
        }
        self.init(parentName: parentName, errorContainer: errorContainer,
                  imapSyncData: imapSyncData, folderID: folder.objectID, folderName: folderName,
                  firstUID: firstUID, lastUID: lastUID)
    }

    public override func shouldRun() -> Bool {
        if !super.shouldRun() {
            return false
        }
        if firstUID == 0 || lastUID == 0 {
            handleError(Constants.errorInvalidParameter(comp), message: "Cannot sync UIDs of 0")
            return false
        }
        if firstUID > lastUID {
            handleError(Constants.errorInvalidParameter(comp),
                        message: "firstUID should be <= lastUID?")
            return false
        }
        return true
    }

    override open func main() {
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
        let folderBuilder = ImapFolderBuilder(
            accountID: self.imapSyncData.connectInfo.accountObjectID,
            backgroundQueue: self.backgroundQueue)
        self.imapSyncData.sync?.delegate = self
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
            waitForFinished()
        }
    }

    func deleteDeletedMails(context: NSManagedObjectContext, existingUIDs: Set<AnyHashable>) {
        guard let folder = context.object(with: folderID)
            as? CdFolder else {
                handleError(Constants.errorCannotFindAccount(component: comp),
                            message: "No folder given")
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
}

extension SyncMessagesOperation: ImapSyncDelegate {

    public func authenticationCompleted(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorIllegalState(comp, stateName: "authenticationCompleted"))
        markAsFinished()
    }

    public func receivedFolderNames(_ sync: ImapSync, folderNames: [String]?) {
        addError(Constants.errorIllegalState(comp, stateName: "receivedFolderNames"))
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
        addError(Constants.errorTimeout(comp))
        markAsFinished()
    }

    public func folderPrefetchCompleted(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorIllegalState(comp, stateName: "messagePrefetchCompleted"))
        markAsFinished()
    }

    public func folderSyncCompleted(_ sync: ImapSync, notification: Notification?) {
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

    public func folderSyncFailed(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorFolderSyncFailed(comp, folderName: folderToOpen))
        markAsFinished()
    }

    public func messageChanged(_ sync: ImapSync, notification: Notification?) {
        // The update of the flags is already handled by `PersistentFolder`.
    }

    public func messagePrefetchCompleted(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorIllegalState(comp, stateName: "messagePrefetchCompleted"))
        markAsFinished()
    }

    public func folderOpenCompleted(_ sync: ImapSync, notification: Notification?) {
        syncMessages(sync)
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
        addError(Constants.errorIllegalState(comp, stateName: "messageStoreCompleted"))
        markAsFinished()
    }

    public func messageStoreFailed(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorIllegalState(comp, stateName: "messageStoreFailed"))
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
