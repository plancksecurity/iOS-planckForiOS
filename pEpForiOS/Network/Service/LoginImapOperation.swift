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
    open override func main() {
        var service = imapSyncData.sync ?? ImapSync(connectInfo: imapSyncData.connectInfo)
        if service.imapState.hasError {
            service = ImapSync(connectInfo: imapSyncData.connectInfo)
        }
        imapSyncData.sync = service

        if !service.imapState.authenticationCompleted {
            service.delegate = self
            service.start()
        } else {
            if service.imapState.currentFolderName != nil {
                // Try to select a (probably) non-existant mailbox,
                // in order to close any other mailbox,
                // without causing a silent expunge caused by CLOSE.
                service.delegate = self
                service.unselectCurrentMailBox()
            } else {
                markAsFinished()
            }
        }
    }
}

extension LoginImapOperation: ImapSyncDelegate {
    public func authenticationCompleted(_ sync: ImapSync, notification: Notification?) {
        imapSyncData.sync = sync

        let context = Record.Context.background
        context.performAndWait {
            if self.isCancelled {
                self.markAsFinished()
                return
            }
            guard let creds = context.object(
                with: self.imapSyncData.connectInfo.credentialsObjectID)
                as? CdServerCredentials else {
                    self.addError(Constants.errorCannotFindServerCredentials(component: self.comp))
                    return
            }

            if !self.isCancelled {
                if creds.needsVerification == true {
                    creds.needsVerification = false
                }

                Record.saveAndWait(context: context)
            }
        }

        markAsFinished()
    }

    public func receivedFolderNames(_ sync: ImapSync, folderNames: [String]?) {
        addIMAPError(ImapSyncError.illegalState(#function))
        markAsFinished()
    }

    public func authenticationFailed(_ sync: ImapSync, notification: Notification?) {
        addIMAPError(ImapSyncError.authenticationFailed(#function))
        markAsFinished()
    }

    public func connectionLost(_ sync: ImapSync, notification: Notification?) {
        addIMAPError(ImapSyncError.connectionLost(#function))
        markAsFinished()
    }

    public func connectionTerminated(_ sync: ImapSync, notification: Notification?) {
        addIMAPError(ImapSyncError.connectionTerminated(#function))
        markAsFinished()
    }

    public func connectionTimedOut(_ sync: ImapSync, notification: Notification?) {
        addIMAPError(ImapSyncError.connectionTimedOut(#function))
        markAsFinished()
    }

    public func folderPrefetchCompleted(_ sync: ImapSync, notification: Notification?) {
        addIMAPError(ImapSyncError.illegalState(#function))
        markAsFinished()
    }

    public func folderSyncCompleted(_ sync: ImapSync, notification: Notification?) {
        addIMAPError(ImapSyncError.illegalState(#function))
        markAsFinished()
    }

    public func folderSyncFailed(_ sync: ImapSync, notification: Notification?) {
        addIMAPError(ImapSyncError.illegalState(#function))
        markAsFinished()
    }

    public func messageChanged(_ sync: ImapSync, notification: Notification?) {
        addIMAPError(ImapSyncError.illegalState(#function))
        markAsFinished()
    }

    public func messagePrefetchCompleted(_ sync: ImapSync, notification: Notification?) {
        addIMAPError(ImapSyncError.illegalState(#function))
        markAsFinished()
    }

    public func folderOpenCompleted(_ sync: ImapSync, notification: Notification?) {
        // Should not generate an error, since we may try to select an non-existant
        // mailbox as alternative to CLOSE.
        markAsFinished()
    }

    public func folderOpenFailed(_ sync: ImapSync, notification: Notification?) {
        // Should not generate an error, since we may try to select an non-existant
        // mailbox as alternative to CLOSE.
        markAsFinished()
    }

    public func folderStatusCompleted(_ sync: ImapSync, notification: Notification?) {
        addIMAPError(ImapSyncError.illegalState(#function))
        markAsFinished()
    }

    public func folderListCompleted(_ sync: ImapSync, notification: Notification?) {
        addIMAPError(ImapSyncError.illegalState(#function))
        markAsFinished()
    }

    public func folderNameParsed(_ sync: ImapSync, notification: Notification?) {
        addIMAPError(ImapSyncError.illegalState(#function))
        markAsFinished()
    }

    public func folderAppendCompleted(_ sync: ImapSync, notification: Notification?) {
        addIMAPError(ImapSyncError.illegalState(#function))
        markAsFinished()
    }

    public func folderAppendFailed(_ sync: ImapSync, notification: Notification?) {
        addIMAPError(ImapSyncError.illegalState(#function))
        markAsFinished()
    }

    public func messageStoreCompleted(_ sync: ImapSync, notification: Notification?) {
        addIMAPError(ImapSyncError.illegalState(#function))
        markAsFinished()
    }

    public func messageStoreFailed(_ sync: ImapSync, notification: Notification?) {
        addIMAPError(ImapSyncError.illegalState(#function))
        markAsFinished()
    }

    public func folderCreateCompleted(_ sync: ImapSync, notification: Notification?) {
        addIMAPError(ImapSyncError.illegalState(#function))
        markAsFinished()
    }

    public func folderCreateFailed(_ sync: ImapSync, notification: Notification?) {
        addIMAPError(ImapSyncError.illegalState(#function))
        markAsFinished()
    }

    public func folderDeleteCompleted(_ sync: ImapSync, notification: Notification?) {
        addIMAPError(ImapSyncError.illegalState(#function))
        markAsFinished()
    }

    public func folderDeleteFailed(_ sync: ImapSync, notification: Notification?) {
        addIMAPError(ImapSyncError.illegalState(#function))
        markAsFinished()
    }

    public func badResponse(_ sync: ImapSync, response: String?) {
        addIMAPError(ImapSyncError.badResponse(response))
        markAsFinished()
    }
}
