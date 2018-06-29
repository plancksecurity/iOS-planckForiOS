//
//  AppendMailsOperationBase.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 13/01/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

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
    public enum EncryptMode {
        // Encrypt messages for myself
        case encryptToMySelf

        // Encrypt messages as if they were outgoing
        case encryptAsOutgoing

        public func encrypt(session: PEPSession, pEpMessageDict: PEPMessageDict,
                            forSelf: PEPIdentity? = nil)
            throws -> (PEP_STATUS, NSDictionary?) {
                switch self {
                case .encryptToMySelf:
                    return try session.encrypt(
                        pEpMessageDict: pEpMessageDict, forSelf: forSelf)
                case .encryptAsOutgoing:
                    return try session.encrypt(pEpMessageDict: pEpMessageDict)
                }
        }
    }

    var syncDelegate: AppendMailsSyncDelegate?

    /** The object ID of the last handled message, so we can modify/delete it on success */
    var lastHandledMessageObjectID: NSManagedObjectID?

    private var targetFolderName: String?
    let targetFolderType: FolderType

    /** On finish, the messageIDs of the messages that have been sent successfully */
    private(set) var successAppendedMessageIDs = [String]()

    /**
     This changes the encryption that is used for the message to be appended.
     */
    private let encryptMode: EncryptMode

    init(parentName: String = #function, appendFolderType: FolderType, imapSyncData: ImapSyncData,
                errorContainer: ServiceErrorProtocol = ErrorContainer(),
                encryptMode: EncryptMode) {
        targetFolderType = appendFolderType
        self.encryptMode = encryptMode
        super.init(parentName: parentName, errorContainer: errorContainer,
                   imapSyncData: imapSyncData)
    }

    override public func main() {
        if !checkImapSync() {
            markAsFinished()
            return
        }
        syncDelegate = AppendMailsSyncDelegate(errorHandler: self)
        imapSyncData.sync?.delegate = syncDelegate

        handleNextMessage()
    }

    func retrieveNextMessage() -> (PEPMessageDict, PEPIdentity, NSManagedObjectID)? {
        Log.shared.errorAndCrash(component: #function,
                                 errorString: "Must be overridden in subclass")
        return nil
    }

    private func retrieveFolderForAppend(
        account: CdAccount, context: NSManagedObjectContext) -> CdFolder? {
        return CdFolder.by(folderType: targetFolderType, account: account, context: context)
    }

    func markLastMessageAsFinished() {
        if let msgID = lastHandledMessageObjectID {
            privateMOC.performAndWait { [weak self] in
                guard let theSelf = self else {
                    Log.shared.errorAndCrash(component: #function, errorString: "I got lost")
                    return
                }
                if let obj = theSelf.privateMOC.object(with: msgID) as? CdMessage {
                    if let msgID = obj.messageID {
                        theSelf.successAppendedMessageIDs.append(msgID)
                    }
                    theSelf.privateMOC.delete(obj)
                    theSelf.privateMOC.saveAndLogErrors()
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
            Log.shared.errorAndCrash(component: #function, errorString: "No target")
            markAsFinished()
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
        let flags = targetFolderType.defaultAppendImapFlags()
        folder.appendMessage(fromRawSource: rawData,
                             flags: flags?.pantomimeFlags(),
                             internalDate: nil)
    }

    func determineTargetFolder(msgID: NSManagedObjectID) {
        if targetFolderName != nil {
            // We already know the target folder, nothing to do
            return
        }
        privateMOC.performAndWait {
            guard let msg = self.privateMOC.object(with: msgID) as? CdMessage else {
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
            guard let cdFolder = self.retrieveFolderForAppend(
                account: account, context: self.privateMOC) else {
                    self.handleError(
                        BackgroundError.GeneralError.invalidParameter(info: self.comp),
                        message: "Cannot find sent folder for message to append")
                    return
            }
            if cdFolder.folder().shouldNotAppendMessages {
                // We are not supposed to append messages to this (probably virtual) mailbox.
                // This is only for savety reasons, we should never come in here as messages
                // should not be marked for appending in the first place.
                // In case it turns out that there *Are* valid cases to reach this, we should
                // also delete the triggering message to avoid that it is processed here on
                // every sync loop.
                Log.shared.errorAndCrash(component: #function,
                                         errorString: "We should never come here.")
                handleNextMessage()
                return
            }
            guard let fn = cdFolder.name else {
                self.handleError(BackgroundError.GeneralError.invalidParameter(info: self.comp),
                                 message: "Need the name for the sent folder")
                return
            }
            self.targetFolderName = fn
        }
    }

    func handleNextMessage() {
        markLastMessageAsFinished()

        guard let (msg, ident, objID) = retrieveNextMessage() else {
            markAsFinished()
            return
        }

        lastHandledMessageObjectID = objID
        determineTargetFolder(msgID: objID)
        let session = PEPSession()
        do {
            let (_, encMsg) = try encryptMode.encrypt(session: session, pEpMessageDict: msg,
                                                      forSelf: ident)
            appendMessage(pEpMessageDict: encMsg as? PEPMessageDict)
        } catch let err as NSError {
            handleError(err, message: "Cannot encrypt message")
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
