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
    let grandOperator: IGrandOperator

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

    let connectInfo: ConnectInfo
    var imapSync: ImapSync!
    var folderBuilder: ImapFolderBuilder!

    public init(grandOperator: IGrandOperator, connectInfo: ConnectInfo, folder: String?) {
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

    func updateFolderNames(folderNames: [String]) {
        let op = StoreFoldersOperation.init(grandOperator: self.grandOperator,
                                            folders: folderNames, email: self.connectInfo.email)
        backgroundQueue.addOperation(op)
    }
}

extension FetchFoldersOperation: ImapSyncDelegate {

    public func authenticationCompleted(sync: ImapSync, notification: NSNotification?) {
        if !self.cancelled {
            sync.waitForFolders()
        }
    }

    public func receivedFolderNames(sync: ImapSync, folderNames: [String]) {
        if !self.cancelled {
            self.updateFolderNames(folderNames)
            waitForFinished()
        }
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
    }

    public func messageChanged(sync: ImapSync, notification: NSNotification?) {
    }

    public func messagePrefetchCompleted(sync: ImapSync, notification: NSNotification?) {
    }

    public func folderOpenCompleted(sync: ImapSync, notification: NSNotification?) {
    }

    public func folderOpenFailed(sync: ImapSync, notification: NSNotification?) {
    }

    public func folderStatusCompleted(sync: ImapSync, notification: NSNotification?) {
    }
}