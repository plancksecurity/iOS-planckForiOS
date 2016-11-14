//
//  PrefetchEmailsOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 15/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation
import CoreData

import MessageModel

/**
 This operation is not intended to be put in a queue (though this should work too).
 It runs asynchronously, but mainly driven by the main runloop through the use of NSStream.
 Therefore it behaves as a concurrent operation, handling the state itself.
 */
open class PrefetchEmailsOperation: ConcurrentBaseOperation {
    let comp = "PrefetchEmailsOperation"

    let connectInfo: EmailConnectInfo
    var sync: ImapSync!
    var folderToOpen: String
    let connectionManager: ConnectionManager

    public init(grandOperator: IGrandOperator, connectInfo: EmailConnectInfo, folder: String?) {
        self.connectInfo = connectInfo
        self.connectionManager = grandOperator.connectionManager
        if let folder = folder {
            folderToOpen = folder
        } else {
            folderToOpen = ImapSync.defaultImapInboxName
        }
    }

    override open func main() {
        if self.isCancelled {
            return
        }

        let context = Record.Context.default
        context.perform() {
            self.process(context: context)
        }
    }

    func process(context: NSManagedObjectContext) {
        let folderBuilder = ImapFolderBuilder.init(connectInfo: self.connectInfo,
                                                   backgroundQueue: self.backgroundQueue)

        guard let account = Record.Context.default.object(with: connectInfo.accountObjectID)
            as? CdAccount else {
                errors.append(Constants.errorCannotFindAccount(component: comp))
                markAsFinished()
                return
        }

        // Treat Inbox specially, as it is the only mailbox
        // that is mandatorily case-insensitive.
        if self.folderToOpen.lowercased() == ImapSync.defaultImapInboxName.lowercased() {
            if let folder = CdFolder.first(with: ["folderType": FolderType.inbox.rawValue,
                                          "account": account]) {
                self.folderToOpen = folder.name!
            }
        }

        self.sync = self.connectionManager.emailSyncConnection(self.connectInfo)
        self.sync.delegate = self
        self.sync.folderBuilder = folderBuilder

        if self.sync.imapState.authenticationCompleted == false {
            self.sync.start()
        } else {
            if self.sync.imapState.currentFolder != nil {
                self.syncMails(self.sync)
            } else {
                self.sync.openMailBox(self.folderToOpen)
            }
        }
    }

    func syncMails(_ sync: ImapSync) {
        do {
            try sync.syncMails()
        } catch let err as NSError {
            addError(err)
            waitForFinished()
        }
    }
}

extension PrefetchEmailsOperation: ImapSyncDelegate {

    public func authenticationCompleted(_ sync: ImapSync, notification: Notification?) {
        if !self.isCancelled {
            sync.openMailBox(folderToOpen)
        }
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
        waitForFinished()
    }

    public func messageChanged(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorIllegalState(comp, stateName: "messageChanged"))
        markAsFinished()
    }

    public func messagePrefetchCompleted(_ sync: ImapSync, notification: Notification?) {
        // do nothing
    }

    public func folderOpenCompleted(_ sync: ImapSync, notification: Notification?) {
        syncMails(sync)
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
