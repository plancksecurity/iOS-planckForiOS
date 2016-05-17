//
//  VerifyImapConnectionOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 28/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation

public class VerifyImapConnectionOperation: ConcurrentBaseOperation {
    let errorDomain = "VerifyImapConnectionOperation"
    var imapSync: ImapSync!
    let connectInfo: ConnectInfo

    init(grandOperator: IGrandOperator, connectInfo: ConnectInfo) {
        self.connectInfo = connectInfo
        super.init(grandOperator: grandOperator)
    }

    public override func main() {
        if self.cancelled {
            return
        }
        imapSync = grandOperator.connectionManager.emailSyncConnection(connectInfo)
        imapSync.delegate = self
        imapSync.start()
    }
}

extension VerifyImapConnectionOperation: ImapSyncDelegate {

    public func authenticationCompleted(sync: ImapSync, notification: NSNotification?) {
        markAsFinished()
    }

    public func receivedFolderNames(sync: ImapSync, folderNames: [String]?) {
    }

    public func authenticationFailed(sync: ImapSync, notification: NSNotification?) {
        grandOperator.setErrorForOperation(self,
                                           error: Constants.errorAuthenticationFailed(errorDomain))
        markAsFinished()
    }

    public func connectionLost(sync: ImapSync, notification: NSNotification?) {
        grandOperator.setErrorForOperation(self, error: Constants.errorConnectionLost(errorDomain))
        markAsFinished()
    }

    public func connectionTerminated(sync: ImapSync, notification: NSNotification?) {
        grandOperator.setErrorForOperation(self,
                                           error: Constants.errorConnectionTerminated(errorDomain))
        markAsFinished()
    }

    public func connectionTimedOut(sync: ImapSync, notification: NSNotification?) {
        grandOperator.setErrorForOperation(self, error: Constants.errorTimeout(errorDomain))
        markAsFinished()
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

    public func folderListCompleted(sync: ImapSync, notification: NSNotification?) {
    }

    public func actionFailed(sync: ImapSync, error: NSError) {
        grandOperator.setErrorForOperation(self, error: error)
    }
}