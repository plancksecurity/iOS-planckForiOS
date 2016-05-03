//
//  VerifyImapConnectionOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 28/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation

class VerifyImapConnectionOperation: BaseOperation {
    let errorDomain = "VerifyImapConnectionOperation"

    let connectInfo: ConnectInfo
    var imapSync: ImapSync!

    init(grandOperator: IGrandOperator, connectInfo: ConnectInfo) {
        self.connectInfo = connectInfo
        super.init(grandOperator: grandOperator)
    }

    override func main() {
        if self.cancelled {
            return
        }
        imapSync = grandOperator.connectionManager.emailSyncConnection(connectInfo)
        imapSync.delegate = self
        imapSync.start()
    }
}

extension VerifyImapConnectionOperation: ImapSyncDelegate {

    func authenticationCompleted(sync: ImapSync, notification: NSNotification?) {
        markAsFinished()
    }

    func receivedFolderNames(sync: ImapSync, folderNames: [String]) {
    }

    func authenticationFailed(sync: ImapSync, notification: NSNotification?) {
        grandOperator.setErrorForOperation(self,
                                           error: Constants.errorAuthenticationFailed(errorDomain))
        markAsFinished()
    }

    func connectionLost(sync: ImapSync, notification: NSNotification?) {
        grandOperator.setErrorForOperation(self, error: Constants.errorConnectionLost(errorDomain))
        markAsFinished()
    }

    func connectionTerminated(sync: ImapSync, notification: NSNotification?) {
        grandOperator.setErrorForOperation(self,
                                           error: Constants.errorConnectionTerminated(errorDomain))
        markAsFinished()
    }

    func connectionTimedOut(sync: ImapSync, notification: NSNotification?) {
        grandOperator.setErrorForOperation(self, error: Constants.errorTimeout(errorDomain))
        markAsFinished()
    }

    func folderPrefetchCompleted(sync: ImapSync, notification: NSNotification?) {
    }

    func messageChanged(sync: ImapSync, notification: NSNotification?) {
    }

    func messagePrefetchCompleted(sync: ImapSync, notification: NSNotification?) {
    }

    func folderOpenCompleted(sync: ImapSync, notification: NSNotification?) {
    }

    func folderOpenFailed(sync: ImapSync, notification: NSNotification?) {
    }

    func folderStatusCompleted(sync: ImapSync, notification: NSNotification?) {
    }
}