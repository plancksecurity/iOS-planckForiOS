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
    var lastSeenUID: UInt?

    public init(parentName: String? = nil, errorContainer: ErrorProtocol = ErrorContainer(),
                imapSyncData: ImapSyncData, folderID: NSManagedObjectID,
                folderName: String, lastUID: UInt) {
        self.folderID = folderID
        self.folderToOpen = folderName
        self.lastUID = lastUID
        super.init(parentName: parentName, errorContainer: errorContainer,
                   imapSyncData: imapSyncData)
    }

    /*
    public convenience init?(imapSyncData: ImapSyncData, folder: CdFolder, lastUID: UInt) {
        guard let folderName = folder.name else {
            return nil
        }
        self.init(imapSyncData: imapSyncData, folderID: folder.objectID, folderName: folderName,
                  lastUID: lastUID)
    }
     */

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
        let folderBuilder = ImapFolderBuilder.init(
            accountID: self.imapSyncData.connectInfo.accountObjectID,
            backgroundQueue: self.backgroundQueue)
        self.imapSync.delegate = self
        self.imapSync.folderBuilder = folderBuilder

        if !self.imapSync.openMailBox(name: self.folderToOpen) {
            self.syncMessages(self.imapSync)
        }
    }

    func syncMessages(_ sync: ImapSync) {
        do {
            try sync.syncMessages(lastUID: lastUID)
        } catch let err as NSError {
            addError(err)
            waitForFinished()
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
        markAsFinished()
    }

    func deleteMessagesInBetween(
        context: NSManagedObjectContext, startUID: UInt, excludingUID: UInt) {
        guard let folder = context.object(with: folderID)
            as? CdFolder else {
                addError(Constants.errorCannotFindAccount(component: comp))
                markAsFinished()
                return
        }
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "CdMessage")
        fetchRequest.predicate = NSPredicate(format: "parent = %@ and uid >= %d and uid < %d",
                                             folder, startUID, excludingUID)
        let request = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        do {
            try context.execute(request)
        } catch {
            addError(error as NSError)
            markAsFinished()
        }
    }

    public func messageChanged(_ sync: ImapSync, notification: Notification?) {
        // The update of the flags is already handled by `PersistentFolder`.
        if let userDict = notification?.userInfo?[PantomimeMessageChanged] as? [String: Any],
            let cwMessage = userDict["Message"] as? CWIMAPMessage {
            let uid = cwMessage.uid()
            if let theLastUID = lastSeenUID, uid - 1 > theLastUID {
                let context = Record.Context.default
                context.performAndWait {
                    self.deleteMessagesInBetween(
                        context: context, startUID: theLastUID + 1, excludingUID: uid)
                    Record.saveAndWait()
                }
            }
            lastSeenUID = uid
        } else {
            addError(Constants.errorIllegalState(
                comp, stateName: "PantomimeMessageChanged without valid message"))
            markAsFinished()
        }
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
