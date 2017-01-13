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

open class AppendMailsOperation: ImapSyncOperation {
    lazy var session = PEPSession()
    lazy var context = Record.Context.background

    /** The object ID of the last handled message, so we can modify/delete it on success */
    var lastHandledMessageObjectID: NSManagedObjectID?

    var targetFolderName: String?

    public init(parentName: String? = nil, imapSyncData: ImapSyncData,
                errorContainer: ErrorProtocol = ErrorContainer()) {
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

    public func retrieveNextMessage() -> (PEPMessage, PEPIdentity, NSManagedObjectID)? {
        var msg: CdMessage?
        context.performAndWait {
            let p = NSPredicate(
                format: "uid = 0 and parent.folderType = %d and sendStatus = %d",
                FolderType.sent.rawValue, SendStatus.smtpDone.rawValue)
            msg = CdMessage.first(with: p)
        }
        if let m = msg, let cdIdent = m.parent?.account?.identity {
            return (m.pEpMessage(), cdIdent.pEpIdentity(), m.objectID)
        }
        return nil
    }

    func markLastMessageAsFinished() {
        if let msgID = lastHandledMessageObjectID {
            context.performAndWait {
                if let obj = self.context.object(with: msgID) as? CdMessage {
                    self.context.delete(obj)
                    Record.save(context: self.context)
                } else {
                    self.handleError(Constants.errorInvalidParameter(self.comp),
                                     message:
                        "Cannot find message just stored in the sent folder".localized)
                    return
                }
            }
        }
    }

    func appendMessage(pEpMessage: PEPMessage?) {
        guard let msg = pEpMessage else {
            handleError(Constants.errorInvalidParameter(comp),
                        message: "Cannot append nil message".localized)
            return
        }
        guard let folderName = targetFolderName else {
            return
        }

        let pantMail = PEPUtil.pantomime(pEpMessage: msg)
        let folder = CWIMAPFolder(name: folderName)
        folder.setStore(imapSync.imapStore)
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
                        "Need a valid message for determining the sent folder name".localized)
                    return
                }
                guard let account = msg.parent?.account else {
                    self.handleError(
                        Constants.errorInvalidParameter(self.comp),
                        message:
                        "Cannot append message without parent folder and this, account".localized)
                    return
                }
                guard let folder = CdFolder.by(folderType: .sent, account: account) else {
                    self.handleError(
                        Constants.errorInvalidParameter(self.comp),
                        message: "Cannot find sent folder for message to append".localized)
                    return
                }
                guard let fn = folder.name else {
                    self.handleError(
                        Constants.errorInvalidParameter(self.comp),
                        message: "Need the name for the sent folder".localized)
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
                handleError(err, message: "Cannot encrypt message".localized)
                appendMessage(pEpMessage: encMsg as? PEPMessage)
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
        addError(Constants.errorIllegalState(comp, stateName: "authenticationCompleted"))
        markAsFinished()
    }

    public func authenticationFailed(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorAuthenticationFailed(comp))
        markAsFinished()
    }

    public func connectionLost(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorConnectionLost(comp))
        markAsFinished()
    }

    public func connectionTerminated(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorConnectionTerminated(comp))
        markAsFinished()
    }

    public func connectionTimedOut(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorConnectionTimeout(comp))
        markAsFinished()
    }

    public func folderPrefetchCompleted(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorIllegalState(comp, stateName: "folderPrefetchCompleted"))
        markAsFinished()
    }

    public func folderSyncCompleted(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorIllegalState(comp, stateName: "folderSyncCompleted"))
        markAsFinished()
    }

    public func messageChanged(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorIllegalState(comp, stateName: "messageChanged"))
        markAsFinished()
    }

    public func messagePrefetchCompleted(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorIllegalState(comp, stateName: "messagePrefetchCompleted"))
        markAsFinished()
    }

    public func folderOpenCompleted(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorIllegalState(comp, stateName: "folderOpenCompleted"))
        markAsFinished()
    }

    public func folderOpenFailed(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorIllegalState(comp, stateName: "folderOpenFailed"))
        markAsFinished()
    }

    public func folderStatusCompleted(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorIllegalState(comp, stateName: "folderStatusCompleted"))
        markAsFinished()
    }

    public func folderListCompleted(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorIllegalState(comp, stateName: "folderListCompleted"))
        markAsFinished()
    }

    public func folderNameParsed(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorIllegalState(comp, stateName: "folderNameParsed"))
        markAsFinished()
    }

    public func folderAppendCompleted(_ sync: ImapSync, notification: Notification?) {
        handleNextMessage()
    }

    public func folderAppendFailed(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorIllegalState(comp, stateName: "folderAppendFailed"))
        markAsFinished()
    }

    public func messageStoreCompleted(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorIllegalState(comp, stateName: "messageStoreCompleted"))
        markAsFinished()
    }

    public func messageStoreFailed(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorIllegalState(comp, stateName: "messageStoreFailed"))
        markAsFinished()
    }

    public func folderCreateCompleted(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorIllegalState(comp, stateName: "folderCreateCompleted"))
        markAsFinished()
    }

    public func folderCreateFailed(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorIllegalState(comp, stateName: "folderCreateFailed"))
        markAsFinished()
    }

    public func folderDeleteCompleted(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorIllegalState(comp, stateName: "folderDeleteCompleted"))
        markAsFinished()
    }

    public func folderDeleteFailed(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorIllegalState(comp, stateName: "folderDeleteFailed"))
        markAsFinished()
    }

    public func actionFailed(_ sync: ImapSync, error: NSError) {
        addError(error)
        markAsFinished()
    }
}
