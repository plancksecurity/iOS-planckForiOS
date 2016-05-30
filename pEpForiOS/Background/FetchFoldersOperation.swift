//
//  FetchFoldersOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 03/05/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation

public class ImapFolderBuilder: NSObject, CWFolderBuilding {
    let connectInfo: ConnectInfo
    let backgroundQueue: NSOperationQueue
    weak var grandOperator: IGrandOperator!

    public init(grandOperator: IGrandOperator, connectInfo: ConnectInfo,
                backgroundQueue: NSOperationQueue) {
        self.connectInfo = connectInfo
        self.grandOperator = grandOperator
        self.backgroundQueue = backgroundQueue
    }

    public func folderWithName(name: String!) -> CWFolder! {
        return PersistentImapFolder(name: name, grandOperator: grandOperator,
                                    connectInfo: connectInfo, backgroundQueue: backgroundQueue)
            as CWFolder
    }
}

/**
 This operation is not intended to be put in a queue.
 It runs asynchronously, but mainly driven by the main runloop through the use of NSStream.
 Therefore it behaves as a concurrent operation, handling the state itself.
 */
public class FetchFoldersOperation: ConcurrentBaseOperation {
    let comp = "FetchFoldersOperation"
    var imapSync: ImapSync!
    let connectInfo: ConnectInfo
    var folderBuilder: ImapFolderBuilder!

    public init(grandOperator: IGrandOperator, connectInfo: ConnectInfo) {
        self.connectInfo = connectInfo

        super.init(grandOperator: grandOperator)

        folderBuilder = ImapFolderBuilder.init(grandOperator: grandOperator,
                                               connectInfo: connectInfo,
                                               backgroundQueue: backgroundQueue)
    }

    public override func main() {
        if self.cancelled {
            return
        }
        imapSync = grandOperator.connectionManager.emailSyncConnection(connectInfo)
        imapSync.delegate = self
        imapSync.folderBuilder = folderBuilder
        imapSync.start()
    }

    func readFolderNamesFromImapSync(sync: ImapSync) {
        if let folderNames = sync.folderNames {
            let op = StoreFoldersOperation.init(grandOperator: self.grandOperator,
                                                folders: folderNames, email: self.connectInfo.email)
            backgroundQueue.addOperation(op)
            waitForFinished()
        }
    }
}

extension FetchFoldersOperation: ImapSyncDelegate {

    public func authenticationCompleted(sync: ImapSync, notification: NSNotification?) {
        if !self.cancelled {
            readFolderNamesFromImapSync(sync)
        }
    }

    public func authenticationFailed(sync: ImapSync, notification: NSNotification?) {
        grandOperator.setErrorForOperation(self, error: Constants.errorAuthenticationFailed(comp))
    }

    public func connectionLost(sync: ImapSync, notification: NSNotification?) {
        grandOperator.setErrorForOperation(self, error: Constants.errorConnectionLost(comp))
    }

    public func connectionTerminated(sync: ImapSync, notification: NSNotification?) {
        grandOperator.setErrorForOperation(self, error: Constants.errorConnectionTerminated(comp))
    }

    public func connectionTimedOut(sync: ImapSync, notification: NSNotification?) {
        grandOperator.setErrorForOperation(self, error: Constants.errorConnectionTimeout(comp))
    }

    public func folderPrefetchCompleted(sync: ImapSync, notification: NSNotification?) {
        grandOperator.setErrorForOperation(self, error: Constants.errorIllegalState(comp,
            stateName: "folderPrefetchCompleted"))
    }

    public func messageChanged(sync: ImapSync, notification: NSNotification?) {
        grandOperator.setErrorForOperation(self, error: Constants.errorIllegalState(comp,
            stateName: "messageChanged"))
    }

    public func messagePrefetchCompleted(sync: ImapSync, notification: NSNotification?) {
        grandOperator.setErrorForOperation(self, error: Constants.errorIllegalState(comp,
            stateName: "messagePrefetchCompleted"))
    }

    public func folderOpenCompleted(sync: ImapSync, notification: NSNotification?) {
        grandOperator.setErrorForOperation(self, error: Constants.errorIllegalState(comp,
            stateName: "folderOpenCompleted"))
    }

    public func folderOpenFailed(sync: ImapSync, notification: NSNotification?) {
        grandOperator.setErrorForOperation(self, error: Constants.errorIllegalState(comp,
            stateName: "folderOpenFailed"))
    }

    public func folderStatusCompleted(sync: ImapSync, notification: NSNotification?) {
        grandOperator.setErrorForOperation(self, error: Constants.errorIllegalState(comp,
            stateName: "folderStatusCompleted"))
    }

    public func folderListCompleted(sync: ImapSync, notification: NSNotification?) {
        readFolderNamesFromImapSync(sync)
    }

    public func actionFailed(sync: ImapSync, error: NSError) {
        grandOperator.setErrorForOperation(self, error: error)
    }
}