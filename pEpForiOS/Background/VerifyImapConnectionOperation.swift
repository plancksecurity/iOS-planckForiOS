//
//  VerifyImapConnectionOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 28/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation

public class VerifyImapConnectionOperation: VerifyServiceOperation {
    let errorDomain = "VerifyImapConnectionOperation"

    public override func main() {
        if self.cancelled {
            return
        }
        service = grandOperator.connectionManager.emailSyncConnectionOneWay(connectInfo)
        (service as! ImapSync).delegate = self
        service.start()
    }
}

extension VerifyImapConnectionOperation: ImapSyncDelegate {
    override func markAsFinished() {
        self.isFinishing = true
        super.markAsFinished()
    }

    public func authenticationCompleted(sync: ImapSync, notification: NSNotification?) {
        self.isFinishing = true
        close(true)
    }

    public func receivedFolderNames(sync: ImapSync, folderNames: [String]?) {
    }

    public func authenticationFailed(sync: ImapSync, notification: NSNotification?) {
        if !isFinishing {
            grandOperator.setErrorForOperation(
                self, error: Constants.errorAuthenticationFailed(errorDomain))
            close(true)
        }
    }

    public func connectionLost(sync: ImapSync, notification: NSNotification?) {
        if !isFinishing {
            grandOperator.setErrorForOperation(
                self, error: Constants.errorConnectionLost(errorDomain))
            isFinishing = true
            markAsFinished()
        }
    }

    public func connectionTerminated(sync: ImapSync, notification: NSNotification?) {
        if !isFinishing {
            grandOperator.setErrorForOperation(
                self, error: Constants.errorConnectionTerminated(errorDomain))
            isFinishing = true
            markAsFinished()
        }
    }

    public func connectionTimedOut(sync: ImapSync, notification: NSNotification?) {
        if !isFinishing {
            grandOperator.setErrorForOperation(self, error: Constants.errorTimeout(errorDomain))
            isFinishing = true
            markAsFinished()
        }
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
        if !isFinishing {
            grandOperator.setErrorForOperation(self, error: error)
            close(true)
        }
   }
}