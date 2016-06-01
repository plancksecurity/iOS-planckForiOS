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
    let folderToOpen: String

    public init(grandOperator: IGrandOperator, connectInfo: ConnectInfo, folder: String?) {
        self.connectInfo = connectInfo
        if let folder = folder {
            folderToOpen = folder
        } else {
            folderToOpen = ImapSync.defaultImapInboxName
        }


        super.init(grandOperator: grandOperator)
    }

    override public func main() {
        if self.cancelled {
            return
        }

        let folderBuilder = ImapFolderBuilder.init(grandOperator: grandOperator,
                                                   connectInfo: connectInfo,
                                                   backgroundQueue: backgroundQueue)

        sync = grandOperator.connectionManager.emailSyncConnection(connectInfo)
        sync.delegate = self
        sync.folderBuilder = folderBuilder

        if sync.imapState.authenticationCompleted == false {
            sync.start()
        } else {
            if sync.imapState.currentFolder != nil {
                syncMails(sync)
            } else {
                sync.openMailBox(folderToOpen)
            }
        }
    }

    func updateFolderNames(folderNames: [String]) {
        let op = StoreFoldersOperation.init(grandOperator: self.grandOperator,
                                            folders: folderNames, email: self.connectInfo.email)
        op.start()
    }

    func syncMails(sync: ImapSync) {
        do {
            try sync.syncMails()
        } catch let err as NSError {
            grandOperator.setErrorForOperation(self, error: err)
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
    }

    public func authenticationFailed(sync: ImapSync, notification: NSNotification?) {
    }

    public func connectionLost(sync: ImapSync, notification: NSNotification?) {
    }

    public func connectionTerminated(sync: ImapSync, notification: NSNotification?) {
    }

    public func connectionTimedOut(sync: ImapSync, notification: NSNotification?) {
    }

    public func folderPrefetchCompleted(sync: ImapSync, notification: NSNotification?) {
        waitForFinished()
    }

    public func messageChanged(sync: ImapSync, notification: NSNotification?) {
    }

    public func messagePrefetchCompleted(sync: ImapSync, notification: NSNotification?) {
    }

    public func folderOpenCompleted(sync: ImapSync, notification: NSNotification?) {
        syncMails(sync)
    }

    public func folderOpenFailed(sync: ImapSync, notification: NSNotification?) {
    }

    public func folderStatusCompleted(sync: ImapSync, notification: NSNotification?) {
    }

    public func folderListCompleted(sync: ImapSync, notification: NSNotification?) {
    }

    public func actionFailed(sync: ImapSync, error: NSError) {
        grandOperator.setErrorForOperation(self, error: error)
    }
}