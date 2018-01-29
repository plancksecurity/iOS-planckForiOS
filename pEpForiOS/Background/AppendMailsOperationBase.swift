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

    func retrieveNextMessage() -> (PEPMessageDict, PEPIdentity, NSManagedObjectID)? {
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
                        BackgroundError.GeneralError.invalidParameter(info: #function),
                        message: "Cannot find message just stored in the sent folder")
                    return
                }
            }
        }
    }

    private func appendMessage(pEpMessageDict: PEPMessageDict?) {
        guard let msg = pEpMessageDict else {
            handleError(BackgroundError.GeneralError.invalidParameter(info: #function),
                        message: "Cannot append nil message")
            return
        }
        guard let folderName = targetFolderName else {
            return
        }

        let pantMail = PEPUtil.pantomime(pEpMessageDict: msg)
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
                    self.handleError(BackgroundError.GeneralError.invalidParameter(info: self.comp),
                                     message:
                        "Need a valid message for determining the sent folder name")
                    return
                }
                guard let account = msg.parent?.account else {
                    self.handleError(BackgroundError.GeneralError.invalidParameter(info: self.comp),
                                     message:
                        "Cannot append message without parent folder and this, account")
                    return
                }
                guard let folder = self.retrieveFolderForAppend(
                    account: account, context: self.context) else {
                        self.handleError(
                            BackgroundError.GeneralError.invalidParameter(info: self.comp),
                            message: "Cannot find sent folder for message to append")
                        return
                }
                guard let fn = folder.name else {
                    self.handleError(BackgroundError.GeneralError.invalidParameter(info: self.comp),
                                     message: "Need the name for the sent folder")
                    return
                }
                self.targetFolderName = fn
            }
        }
    }

    final func handleNextMessage() {
        markLastMessageAsFinished()

        guard let (msg, ident, objID) = retrieveNextMessage(),
            !ident.providerDoesHandleAppend(forFolderOfType: targetFolderType) else {
                markAsFinished()
                return
        }
        lastHandledMessageObjectID = objID
        determineTargetFolder(msgID: objID)
        let session = PEPSession()
        let (status, encMsg) = session.encrypt(
            pEpMessageDict: msg, forIdentity: ident)
        let (encMsg2, error) = PEPUtil.check(
            comp: comp, status: status, encryptedMessage: encMsg)
        if let err = error {
            handleError(err, message: "Cannot encrypt message")
            appendMessage(pEpMessageDict: msg as PEPMessageDict)
        } else {
            appendMessage(pEpMessageDict: encMsg2 as? PEPMessageDict)
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
