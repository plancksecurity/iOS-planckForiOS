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
            markAsFinished()
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
        addIMAPError(Constants.errorIllegalState(comp, stateName: "receivedFolderNames"))
        markAsFinished()
    }

    public func authenticationFailed(_ sync: ImapSync, notification: Notification?) {
        addIMAPError(Constants.errorAuthenticationFailed(comp))
        markAsFinished()
    }

    public func connectionLost(_ sync: ImapSync, notification: Notification?) {
        addIMAPError(Constants.errorConnectionLost(comp))
        markAsFinished()
    }

    public func connectionTerminated(_ sync: ImapSync, notification: Notification?) {
        addIMAPError(Constants.errorConnectionTerminated(comp))
        markAsFinished()
    }

    public func connectionTimedOut(_ sync: ImapSync, notification: Notification?) {
        addIMAPError(Constants.errorTimeout(comp))
        markAsFinished()
    }

    public func folderPrefetchCompleted(_ sync: ImapSync, notification: Notification?) {
        addIMAPError(Constants.errorIllegalState(comp, stateName: "folderPrefetchCompleted"))
        markAsFinished()
    }

    public func folderSyncCompleted(_ sync: ImapSync, notification: Notification?) {
        addIMAPError(Constants.errorIllegalState(comp, stateName: "folderSyncCompleted"))
        markAsFinished()
    }

    public func folderSyncFailed(_ sync: ImapSync, notification: Notification?) {
        addIMAPError(Constants.errorIllegalState(comp, stateName: "folderSyncFailed"))
        markAsFinished()
    }

    public func messageChanged(_ sync: ImapSync, notification: Notification?) {
        addIMAPError(Constants.errorIllegalState(comp, stateName: "messageChanged"))
        markAsFinished()
    }

    public func messagePrefetchCompleted(_ sync: ImapSync, notification: Notification?) {
        addIMAPError(Constants.errorIllegalState(comp, stateName: "messagePrefetchCompleted"))
        markAsFinished()
    }

    public func folderOpenCompleted(_ sync: ImapSync, notification: Notification?) {
        addIMAPError(Constants.errorIllegalState(comp, stateName: "folderOpenCompleted"))
        markAsFinished()
    }

    public func folderOpenFailed(_ sync: ImapSync, notification: Notification?) {
        addIMAPError(Constants.errorIllegalState(comp, stateName: "folderOpenFailed"))
        markAsFinished()
    }

    public func folderStatusCompleted(_ sync: ImapSync, notification: Notification?) {
        addIMAPError(Constants.errorIllegalState(comp, stateName: "folderStatusCompleted"))
        markAsFinished()
    }

    public func folderListCompleted(_ sync: ImapSync, notification: Notification?) {
        addIMAPError(Constants.errorIllegalState(comp, stateName: "folderListCompleted"))
        markAsFinished()
    }

    public func folderNameParsed(_ sync: ImapSync, notification: Notification?) {
        addIMAPError(Constants.errorIllegalState(comp, stateName: "folderNameParsed"))
        markAsFinished()
    }

    public func folderAppendCompleted(_ sync: ImapSync, notification: Notification?) {
        addIMAPError(Constants.errorIllegalState(comp, stateName: "folderAppendCompleted"))
        markAsFinished()
    }

    public func folderAppendFailed(_ sync: ImapSync, notification: Notification?) {
        addIMAPError(Constants.errorIllegalState(comp, stateName: "folderAppendFailed"))
        markAsFinished()
    }

    public func messageStoreCompleted(_ sync: ImapSync, notification: Notification?) {
        addIMAPError(Constants.errorIllegalState(comp, stateName: "messageStoreCompleted"))
        markAsFinished()
    }

    public func messageStoreFailed(_ sync: ImapSync, notification: Notification?) {
        addIMAPError(Constants.errorIllegalState(comp, stateName: "messageStoreFailed"))
        markAsFinished()
    }

    public func folderCreateCompleted(_ sync: ImapSync, notification: Notification?) {
        addIMAPError(Constants.errorIllegalState(comp, stateName: "folderCreateCompleted"))
        markAsFinished()
    }

    public func folderCreateFailed(_ sync: ImapSync, notification: Notification?) {
        addIMAPError(Constants.errorIllegalState(comp, stateName: "folderCreateFailed"))
        markAsFinished()
    }

    public func folderDeleteCompleted(_ sync: ImapSync, notification: Notification?) {
        addIMAPError(Constants.errorIllegalState(comp, stateName: "folderDeleteCompleted"))
        markAsFinished()
    }

    public func folderDeleteFailed(_ sync: ImapSync, notification: Notification?) {
        addIMAPError(Constants.errorIllegalState(comp, stateName: "folderDeleteFailed"))
        markAsFinished()
    }

    public func actionFailed(_ sync: ImapSync, error: NSError) {
        addIMAPError(error)
        markAsFinished()
    }
}
