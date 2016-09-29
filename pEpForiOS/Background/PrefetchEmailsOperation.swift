//
//  PrefetchEmailsOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 15/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation
import CoreData

/**
 This operation is not intended to be put in a queue (though this should work too).
 It runs asynchronously, but mainly driven by the main runloop through the use of NSStream.
 Therefore it behaves as a concurrent operation, handling the state itself.
 */
public class PrefetchEmailsOperation: ConcurrentBaseOperation {
    let comp = "PrefetchEmailsOperation"

    let connectInfo: ConnectInfo
    var sync: ImapSync!
    var folderToOpen: String
    let connectionManager: ConnectionManager

    public init(grandOperator: IGrandOperator, connectInfo: ConnectInfo, folder: String?) {
        self.connectInfo = connectInfo
        self.connectionManager = grandOperator.connectionManager
        if let folder = folder {
            folderToOpen = folder
        } else {
            folderToOpen = ImapSync.defaultImapInboxName
        }
        super.init(coreDataUtil: grandOperator.coreDataUtil)
    }

    override public func main() {
        if self.cancelled {
            return
        }

        privateMOC.performBlock() {
            let folderBuilder = ImapFolderBuilder.init(coreDataUtil: self.coreDataUtil,
                connectInfo: self.connectInfo,
                backgroundQueue: self.backgroundQueue)

            // Treat Inbox specially, as it is the only mailbox
            // that is mandatorily case-insensitive.
            if self.folderToOpen.lowercaseString == ImapSync.defaultImapInboxName.lowercaseString {
                if let folder = self.model.folderByType(.Inbox, email: self.connectInfo.email) {
                    self.folderToOpen = folder.name
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
    }

    func syncMails(sync: ImapSync) {
        do {
            try sync.syncMails()
        } catch let err as NSError {
            addError(err)
            waitForFinished()
        }
    }
}

extension PrefetchEmailsOperation: ImapSyncDelegate {

    public func authenticationCompleted(sync: ImapSync, notification: NSNotification?) {
        if !self.cancelled {
            sync.openMailBox(folderToOpen)
        }
    }

    public func receivedFolderNames(sync: ImapSync, folderNames: [String]?) {
        addError(Constants.errorIllegalState(comp, stateName: "receivedFolderNames"))
        markAsFinished()
    }

    public func authenticationFailed(sync: ImapSync, notification: NSNotification?) {
        addError(Constants.errorAuthenticationFailed(comp))
        markAsFinished()
    }

    public func connectionLost(sync: ImapSync, notification: NSNotification?) {
        addError(Constants.errorConnectionLost(comp))
        markAsFinished()
    }

    public func connectionTerminated(sync: ImapSync, notification: NSNotification?) {
        addError(Constants.errorConnectionTerminated(comp))
        markAsFinished()
    }

    public func connectionTimedOut(sync: ImapSync, notification: NSNotification?) {
        addError(Constants.errorTimeout(comp))
        markAsFinished()
    }

    public func folderPrefetchCompleted(sync: ImapSync, notification: NSNotification?) {
        waitForFinished()
    }

    public func messageChanged(sync: ImapSync, notification: NSNotification?) {
        addError(Constants.errorIllegalState(comp, stateName: "messageChanged"))
        markAsFinished()
    }

    public func messagePrefetchCompleted(sync: ImapSync, notification: NSNotification?) {
        // do nothing
    }

    public func folderOpenCompleted(sync: ImapSync, notification: NSNotification?) {
        syncMails(sync)
    }

    public func folderOpenFailed(sync: ImapSync, notification: NSNotification?) {
        addError(Constants.errorIllegalState(comp, stateName: "folderOpenFailed"))
        markAsFinished()
    }

    public func folderStatusCompleted(sync: ImapSync, notification: NSNotification?) {
        addError(Constants.errorIllegalState(comp, stateName: "folderStatusCompleted"))
        markAsFinished()
    }

    public func folderListCompleted(sync: ImapSync, notification: NSNotification?) {
        addError(Constants.errorIllegalState(comp, stateName: "folderListCompleted"))
        markAsFinished()
    }

    public func folderNameParsed(sync: ImapSync, notification: NSNotification?) {
        addError(Constants.errorIllegalState(comp, stateName: "folderNameParsed"))
        markAsFinished()
    }

    public func folderAppendCompleted(sync: ImapSync, notification: NSNotification?) {
        addError(Constants.errorIllegalState(comp, stateName: "folderAppendCompleted"))
        markAsFinished()
    }

    public func folderAppendFailed(sync: ImapSync, notification: NSNotification?) {
        addError(Constants.errorIllegalState(comp, stateName: "folderAppendFailed"))
        markAsFinished()
    }

    public func messageStoreCompleted(sync: ImapSync, notification: NSNotification?) {
        addError(Constants.errorIllegalState(comp, stateName: "messageStoreCompleted"))
        markAsFinished()
    }

    public func messageStoreFailed(sync: ImapSync, notification: NSNotification?) {
        addError(Constants.errorIllegalState(comp, stateName: "messageStoreFailed"))
        markAsFinished()
    }

    public func folderCreateCompleted(sync: ImapSync, notification: NSNotification?) {
        addError(Constants.errorIllegalState(comp, stateName: "folderCreateCompleted"))
        markAsFinished()
    }

    public func folderCreateFailed(sync: ImapSync, notification: NSNotification?) {
        addError(Constants.errorIllegalState(comp, stateName: "folderCreateFailed"))
        markAsFinished()
    }

    public func folderDeleteCompleted(sync: ImapSync, notification: NSNotification?) {
        addError(Constants.errorIllegalState(comp, stateName: "folderDeleteCompleted"))
        markAsFinished()
    }

    public func folderDeleteFailed(sync: ImapSync, notification: NSNotification?) {
        addError(Constants.errorIllegalState(comp, stateName: "folderDeleteFailed"))
        markAsFinished()
    }

    public func actionFailed(sync: ImapSync, error: NSError) {
        addError(error)
        markAsFinished()
    }
}