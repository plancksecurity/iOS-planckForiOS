//
//  LoginImapOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 06/12/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit
import MessageModel

public class LoginImapOperation: ImapSyncOperation {
    var syncDelegate: LoginImapSyncDelegate?
    var capabilities: Set<String>?
    var service: ImapSync

    override init(parentName: String = #function,
                  errorContainer: ServiceErrorProtocol = ErrorContainer(),
                  imapSyncData: ImapSyncData) {
        service = imapSyncData.sync ?? ImapSync(connectInfo: imapSyncData.connectInfo)
        super.init(parentName: parentName, errorContainer: errorContainer,
                   imapSyncData: imapSyncData)
    }

    public override func main() {
        if isCancelled {
            markAsFinished()
            return
        }

        if service.imapState.hasError {
            service = ImapSync(connectInfo: imapSyncData.connectInfo)
        }
        imapSyncData.sync = service

        syncDelegate = LoginImapSyncDelegate(errorHandler: self)
        if !service.imapState.authenticationCompleted {
            service.delegate = syncDelegate
            service.start()
        } else if service.imapState.isIdling {
            service.delegate = syncDelegate
            service.exitIdle()
        } else {
            syncDelegate = nil
            markAsFinished()
        }
    }

    override func markAsFinished() {
        syncDelegate = nil
        super.markAsFinished()
    }
}

class LoginImapSyncDelegate: DefaultImapSyncDelegate {
    override func authenticationCompleted(_ sync: ImapSync, notification: Notification?) {
        guard let op = errorHandler as? LoginImapOperation else {
            return
        }
        op.imapSyncData.sync = sync

        op.capabilities = sync.capabilities
        op.markAsFinished()
    }

    override func folderOpenCompleted(_ sync: ImapSync, notification: Notification?) {
        (errorHandler as? ImapSyncOperation)?.markAsFinished()
    }

    override func folderOpenFailed(_ sync: ImapSync, notification: Notification?) {
        // Should not generate an error, since we may try to select an non-existant
        // mailbox as alternative to CLOSE.
        (errorHandler as? ImapSyncOperation)?.markAsFinished()
    }

    override func idleFinished(_ sync: ImapSync, notification: Notification?) {
        (errorHandler as? ImapSyncOperation)?.markAsFinished()
    }
}
