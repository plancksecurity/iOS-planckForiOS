//
//  AppendMailsOperationBase.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 13/01/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit
import CoreData

import MessageModel

/**
 Base class for storing mails in any type of folder.

 Stores messges retreived by `retrieveNextMessage` to folder of type `targetFolderType`.
 Mails are encrypted whenever possible before storing it in the target folder .

 Subclasses MUST override `retrieveNextMessage`
 For marking the message as done, you MAY overwrite `markLastMessageAsFinished`.
 */
public class AppendMailsOperationBase: ImapSyncOperation {
    lazy private(set) var context = Record.Context.background

    var syncDelegate: AppendMailsSyncDelegate?

    /** The object ID of the last handled message, so we can modify/delete it on success */
    var lastHandledMessageObjectID: NSManagedObjectID?

    private var targetFolderName: String?
    let targetFolderType: FolderType

    /** On finish, the messageIDs of the messages that have been sent successfully */
    private(set) var successAppendedMessageIDs = [String]()

    init(parentName: String = #function, appendFolderType: FolderType, imapSyncData: ImapSyncData,
                errorContainer: ServiceErrorProtocol = ErrorContainer()) {
        targetFolderType = appendFolderType
        super.init(parentName: parentName, errorContainer: errorContainer,
                   imapSyncData: imapSyncData)
    }

    override public func main() {
        if !shouldRun() {
            return
        }

        if !checkImapSync() {
            return
        }

        syncDelegate = AppendMailsSyncDelegate(errorHandler: self)
        imapSyncData.sync?.delegate = syncDelegate

        handleNextMessage()
    }

    func retrieveNextMessage() -> (PEPMessage, PEPIdentity, NSManagedObjectID)? {
        Log.shared.errorAndCrash(component: #function, errorString: "Must be overridden in subclass")
        return nil
    }

    private func retrieveFolderForAppend(
        account: CdAccount, context: NSManagedObjectContext) -> CdFolder? {
        return CdFolder.by(folderType: targetFolderType, account: account, context: context)
    }

    func markLastMessageAsFinished() {
        if let msgID = lastHandledMessageObjectID {
            context.performAndWait { [weak self] in
                guard let theSelf = self else {
                    return
                }
                if let obj = theSelf.context.object(with: msgID) as? CdMessage {
                    if let msgID = obj.messageID {
                        theSelf.successAppendedMessageIDs.append(msgID)
                    }
                    theSelf.context.delete(obj)
                    theSelf.context.saveAndLogErrors()
                } else {
                    theSelf.handleError(
                        Constants.errorInvalidParameter(theSelf.comp),
                        message:
                        NSLocalizedString("Cannot find message just stored in the sent folder",
                                          comment: "Background operation error message"))
                    return
                }
            }
        }
    }

    private func appendMessage(pEpMessage: PEPMessage?) {
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

    final func handleNextMessage() {
        markLastMessageAsFinished()

        if let (msg, ident, objID) = retrieveNextMessage() {
            lastHandledMessageObjectID = objID
            determineTargetFolder(msgID: objID)
            let session = PEPSessionCreator.shared.newSession()
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

    override func markAsFinished() {
        syncDelegate = nil
        super.markAsFinished()
    }
}

class AppendMailsSyncDelegate: DefaultImapSyncDelegate {
    public override func folderAppendCompleted(_ sync: ImapSync, notification: Notification?) {
        (errorHandler as? AppendMailsOperationBase)?.handleNextMessage()
    }

    public override func folderAppendFailed(_ sync: ImapSync, notification: Notification?) {
        (errorHandler as? AppendMailsOperationBase)?.addIMAPError(ImapSyncError.folderAppendFailed)
        (errorHandler as? AppendMailsOperationBase)?.markAsFinished()
    }
}
