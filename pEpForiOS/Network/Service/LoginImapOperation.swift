//
//  LoginImapOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 06/12/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

import MessageModel

open class LoginImapOperation: ImapSyncOperation {
    var syncDelegate: LoginImapSyncDelegate?
    var capabilities: Set<String>?

    public override init(parentName: String? = nil,
                         errorContainer: ServiceErrorProtocol = ErrorContainer(),
                         imapSyncData: ImapSyncData) {
        super.init(parentName: parentName, errorContainer: errorContainer,
                   imapSyncData: imapSyncData)
    }

    open override func main() {
        var service = imapSyncData.sync ?? ImapSync(connectInfo: imapSyncData.connectInfo)
        if service.imapState.hasError {
            service = ImapSync(connectInfo: imapSyncData.connectInfo)
        }
        imapSyncData.sync = service

        syncDelegate = LoginImapSyncDelegate(errorHandler: self)
        if !service.imapState.authenticationCompleted {
            service.delegate = syncDelegate
            service.start()
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
    public override func authenticationCompleted(_ sync: ImapSync, notification: Notification?) {
        guard let op = errorHandler as? LoginImapOperation else {
            return
        }
        op.imapSyncData.sync = sync

        op.capabilities = sync.capabilities
        let context = Record.Context.background
        op.imapSyncData.connectInfo.unsetNeedsVerificationAndFinish(context: context, operation: op)
    }

    public override func folderOpenCompleted(_ sync: ImapSync, notification: Notification?) {
        // Should not generate an error, since we may try to select an non-existant
        // mailbox as alternative to CLOSE.
        (errorHandler as? ImapSyncOperation)?.markAsFinished()
    }

    public override func folderOpenFailed(_ sync: ImapSync, notification: Notification?) {
        // Should not generate an error, since we may try to select an non-existant
        // mailbox as alternative to CLOSE.
        (errorHandler as? ImapSyncOperation)?.markAsFinished()
    }
}
