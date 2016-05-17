//
//  FetchMailOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 17/05/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation

public class FetchMailOperation: ConcurrentBaseOperation {
    let connectInfo: ConnectInfo
    let folderName: String
    let uid: Int

    public init(grandOperator: IGrandOperator, connectInfo: ConnectInfo, folderName: String,
                uid: Int) {
        self.connectInfo = connectInfo
        self.folderName = folderName
        self.uid = uid
        super.init(grandOperator: grandOperator)
    }

    public override func main() {
        let folderBuilder = ImapFolderBuilder.init(grandOperator: grandOperator,
                                                   connectInfo: connectInfo,
                                                   backgroundQueue: backgroundQueue)

        let imapSync = grandOperator.connectionManager.emailSyncConnection(connectInfo)
        imapSync.delegate = self
        imapSync.folderBuilder = folderBuilder

        if imapSync.imapState.authenticationCompleted == false {
            imapSync.start()
        } else {
            imapSync.fetchMailFromFolderNamed(folderName, uid: uid)
        }
    }
}

extension FetchMailOperation: ImapSyncDelegate {

    public func authenticationCompleted(sync: ImapSync, notification: NSNotification?) {
        if !self.cancelled {
            sync.openMailBox(folderName, prefetchMails: false)
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
    }

    public func messageChanged(sync: ImapSync, notification: NSNotification?) {
    }

    public func messagePrefetchCompleted(sync: ImapSync, notification: NSNotification?) {
        if let message = notification?.userInfo?["Message"] as? CWIMAPMessage {
            let op = StorePrefetchedMailOperation.init(grandOperator: grandOperator,
                                                       accountEmail: connectInfo.email,
                                                       message: message)
            backgroundQueue.addOperation(op)
            waitForFinished()
        }
    }

    public func folderOpenCompleted(sync: ImapSync, notification: NSNotification?) {
        sync.fetchMailFromFolderNamed(folderName, uid: uid)
    }

    public func folderOpenFailed(sync: ImapSync, notification: NSNotification?) {
    }

    public func folderStatusCompleted(sync: ImapSync, notification: NSNotification?) {
    }

    public func folderListCompleted(sync: ImapSync, notification: NSNotification?) {
    }

    public func actionFailed(sync: ImapSync, error: NSError) {
        grandOperator.setErrorForOperation(self, error: error)
        waitForFinished()
    }
}