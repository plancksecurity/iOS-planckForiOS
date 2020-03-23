//
//  LoginImapOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 06/12/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation
import CoreData

class LoginImapOperation: ImapSyncOperation {
    override public func main() {
        if isCancelled {
            waitForBackgroundTasksAndFinish()
            return
        }

        syncDelegate = LoginImapSyncDelegate(errorHandler: self)
        if !imapConnection.authenticationCompleted {
            imapConnection.delegate = syncDelegate
            imapConnection.start()
        } else if imapConnection.isIdling {
            imapConnection.delegate = syncDelegate
            imapConnection.exitIdle()
            waitForBackgroundTasksAndFinish()
        } else {
            waitForBackgroundTasksAndFinish()
        }
    }
}

// MARK: - Callback Handler

extension LoginImapOperation {
    fileprivate func handleAuthenticationCompleted(imapConnection: ImapConnectionProtocol) {
        waitForBackgroundTasksAndFinish()
    }
}

class LoginImapSyncDelegate: DefaultImapConnectionDelegate {
    override func authenticationCompleted(_ imapConnection: ImapConnectionProtocol, notification: Notification?) {
        guard let op = errorHandler as? LoginImapOperation else {
            return
        }
        op.handleAuthenticationCompleted(imapConnection: imapConnection)
    }

    override func idleFinished(_ imapConnection: ImapConnectionProtocol, notification: Notification?) {
        (errorHandler as? ImapSyncOperation)?.waitForBackgroundTasksAndFinish()
    }
}
