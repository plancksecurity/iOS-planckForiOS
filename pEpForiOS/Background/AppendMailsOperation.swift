//
//  AppendMailsOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 13/01/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit
import CoreData

import MessageModel

/**
 Stores SMTPed mails in the sent folder. Can be used more generically for storing mails
 in other types of folders. Overwrite `retrieveNextMessage` and `retrieveFolderForAppend`.
 For marking the message as done, overwrite `markLastMessageAsFinished`.
 */
open class AppendMailsOperation: ImapSyncOperation {
    lazy var session = PEPSession()
    lazy var context = Record.Context.background

    /** The object ID of the last handled message, so we can modify/delete it on success */
    var lastHandledMessageObjectID: NSManagedObjectID?

    var targetFolderName: String?

    public init(parentName: String? = nil, imapSyncData: ImapSyncData,
                errorContainer: ServiceErrorProtocol = ErrorContainer()) {
        super.init(parentName: parentName, errorContainer: errorContainer,
                   imapSyncData: imapSyncData)
    }

    override open func main() {
        if !shouldRun() {
            return
        }

        if !checkImapSync() {
            return
        }

        imapSyncData.sync?.delegate = self

        handleNextMessage()
    }

    func retrieveNextMessage() -> (PEPMessage, PEPIdentity, NSManagedObjectID)? {
        var msg: CdMessage?
        context.performAndWait {
            let p = NSPredicate(
                format: "uid = 0 and parent.folderType = %d and sendStatus = %d",
                FolderType.sent.rawValue, SendStatus.smtpDone.rawValue)
            msg = CdMessage.first(predicate: p, in: self.context)
        }
        if let m = msg, let cdIdent = m.parent?.account?.identity {
            return (m.pEpMessage(), cdIdent.pEpIdentity(), m.objectID)
        }
        return nil
    }

    func retrieveFolderForAppend(
        account: CdAccount, context: NSManagedObjectContext) -> CdFolder? {
        return CdFolder.by(folderType: .sent, account: account, context: context)
    }

    func markLastMessageAsFinished() {
        if let msgID = lastHandledMessageObjectID {
            context.performAndWait {
                if let obj = self.context.object(with: msgID) as? CdMessage {
                    self.context.delete(obj)
                    Record.save(context: self.context)
                } else {
                    self.handleError(
                        Constants.errorInvalidParameter(self.comp),
                        message:
                        NSLocalizedString("Cannot find message just stored in the sent folder",
                                          comment: "Background operation error message"))
                    return
                }
            }
        }
    }

    func appendMessage(pEpMessage: PEPMessage?) {
        guard let msg = pEpMessage else {
            handleError(Constants.errorInvalidParameter(comp),
                        message: NSLocalizedString("Cannot append nil message",
                                                   comment: "Background operation error message"))
            return
        }
        guard let folderName = targetFolderName else {
            return
        }

        let pantMail = PEPUtil.pantomime(pEpMessage: msg)
        let folder = CWIMAPFolder(name: folderName)
        if let sync = imapSyncData.sync {
            folder.setStore(sync.imapStore)
        }
        guard let rawData = pantMail.dataValue() else {
            markAsFinished()
            return
        }
        folder.appendMessage(fromRawSource: rawData, flags: nil, internalDate: nil)
    }

    func determineTargetFolder(msgID: NSManagedObjectID) {
        if targetFolderName == nil {
            context.performAndWait {
                guard let msg = self.context.object(with: msgID) as? CdMessage else {
                    self.handleError(
                        Constants.errorInvalidParameter(self.comp),
                        message:
                        NSLocalizedString(
                            "Need a valid message for determining the sent folder name",
                            comment: "Background operation error message"))
                    return
                }
                guard let account = msg.parent?.account else {
                    self.handleError(
                        Constants.errorInvalidParameter(self.comp),
                        message:
                        NSLocalizedString(
                            "Cannot append message without parent folder and this, account",
                            comment: "Background operation error message"))
                    return
                }
                guard let folder = self.retrieveFolderForAppend(
                    account: account, context: self.context) else {
                        self.handleError(
                            Constants.errorInvalidParameter(self.comp),
                            message:
                            NSLocalizedString(
                                "Cannot find sent folder for message to append",
                                comment: "Background operation error message"))
                        return
                }
                guard let fn = folder.name else {
                    self.handleError(
                        Constants.errorInvalidParameter(self.comp),
                        message:
                        NSLocalizedString(
                            "Need the name for the sent folder",
                            comment: "Background operation error message"))
                    return
                }
                self.targetFolderName = fn
            }
        }
    }

    func handleNextMessage() {
        markLastMessageAsFinished()

        if let (msg, ident, objID) = retrieveNextMessage() {
            lastHandledMessageObjectID = objID
            determineTargetFolder(msgID: objID)
            let (status, encMsg) = session.encrypt(pEpMessageDict: msg, forIdentity: ident)
            let (encMsg2, error) = PEPUtil.check(
                comp: comp, status: status, encryptedMessage: encMsg)
            if let err = error {
                handleError(
                    err,
                    message: NSLocalizedString(
                        "Cannot encrypt message",
                        comment: "Background operation error message"))
                appendMessage(pEpMessage: msg as PEPMessage)
            } else {
                appendMessage(pEpMessage: encMsg2 as? PEPMessage)
            }
        } else {
            markAsFinished()
        }
    }
}

extension AppendMailsOperation: ImapSyncDelegate {
    public func authenticationCompleted(_ sync: ImapSync, notification: Notification?) {
        addIMAPError(Constants.errorIllegalState(comp, stateName: "authenticationCompleted"))
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
        addIMAPError(Constants.errorConnectionTimeout(comp))
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
        handleNextMessage()
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

    public func badResponse(_ sync: ImapSync, response: String?) {
        addIMAPError(ImapSyncError.badResponse(response))
        markAsFinished()
    }
}
