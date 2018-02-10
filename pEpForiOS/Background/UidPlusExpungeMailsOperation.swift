//
//  UidPlusExpungeMailsOperation.swift
//  pEp
//
//  Created by Andreas Buff on 10.02.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel

class UidPlusExpungeMailsOperation: ImapSyncOperation {
//    var syncDelegate: AppendMailsSyncDelegate?
//
//    /** The object ID of the last handled message, so we can modify/delete it on success */
//    var lastHandledMessage: Message
//
//    private var targetFolderName: String?
//    let targetFolderType: FolderType
//
//    /** On finish, the messageIDs of the messages that have been sent successfully */
//    private(set) var successAppendedMessageIDs = [String]()
//
//    init(parentName: String = #function, appendFolderType: FolderType, imapSyncData: ImapSyncData,
//         errorContainer: ServiceErrorProtocol = ErrorContainer()) {
//        targetFolderType = appendFolderType
//        super.init(parentName: parentName, errorContainer: errorContainer,
//                   imapSyncData: imapSyncData)
//    }
//
//    override public func main() {
//        if !shouldRun() {
//            return
//        }
//
//        if !checkImapSync() {
//            return
//        }
//
//        syncDelegate = AppendMailsSyncDelegate(errorHandler: self)
//        imapSyncData.sync?.delegate = syncDelegate
//
//        handleNextMessage()
//    }
//
//    //BUFF: go on
////    func retrieveNextMessage() -> Message? {
////        MessageModel.performAndWait {
////            Message.se
////        }
////
////        context.performAndWait {
////            guard let folder = self.context.object(with: self.folderObjectID) as? CdFolder else {
////                return
////            }
////            let p = NSPredicate(
////                format: "parent = %@ AND imap.localFlags.flagDeleted = true AND imap.trashedStatusRawValue = %d AND parent.account = %@",
////                folder, Message.TrashedStatus.shouldBeTrashed.rawValue,
////                imapSyncData.connectInfo.accountObjectID)
////
////            guard let msg = CdMessage.first(predicate: p, in: self.context),
////                let cdIdent = msg.parent?.account?.identity else {
////                    return
////            }
////            result = (msg.pEpMessageDict(), cdIdent.pEpIdentity(), msg.objectID)
////        }
////        return result
////    }
//
//    private func retrieveFolderForAppend(
//        account: CdAccount, context: NSManagedObjectContext) -> CdFolder? {
//        return CdFolder.by(folderType: targetFolderType, account: account, context: context)
//    }
//
//    func deleteLastExpungedMessage() {
//        guard let msgID = lastHandledMessageObjectID else {
//            return
//        }
//        //BUFF: delete msg
////        context.performAndWait {
////            if let obj = self.context.object(with: msgID) as? CdMessage {
////                let imap = obj.imapFields(context: self.context)
////                imap.trashedStatus = Message.TrashedStatus.trashed
////                obj.imap = imap
////                self.context.saveAndLogErrors()
////            } else {
////
////
////
////                self.handleError(BackgroundError.GeneralError.invalidParameter(info:self.comp),
////                                 message: "Cannot find message just stored in the sent folder")
////                return
////            }
////        }
//    }
//
//    private func expungeMessage(pEpMessageDict: PEPMessageDict?) {
//        guard let msg = pEpMessageDict else {
//            handleError(BackgroundError.GeneralError.invalidParameter(info: #function),
//                        message: "Cannot append nil message")
//            return
//        }
//        guard let folderName = targetFolderName else {
//            return
//        }
//
//        let pantMail = PEPUtil.pantomime(pEpMessageDict: msg)
//        let folder = CWIMAPFolder(name: folderName)
//        if let sync = imapSyncData.sync {
//            folder.setStore(sync.imapStore)
//        }
//        guard let rawData = pantMail.dataValue() else {
//            markAsFinished()
//            return
//        }
//        folder.appendMessage(fromRawSource: rawData, flags: nil, internalDate: nil)
//    }
//
//    func determineTargetFolder(msgID: NSManagedObjectID) {
//        if targetFolderName != nil {
//            // We already know the target folder, nothing to do
//            return
//        }
//        context.performAndWait {
//            guard let msg = self.context.object(with: msgID) as? CdMessage else {
//                self.handleError(BackgroundError.GeneralError.invalidParameter(info: self.comp),
//                                 message:
//                    "Need a valid message for determining the sent folder name")
//                return
//            }
//            guard let account = msg.parent?.account else {
//                self.handleError(BackgroundError.GeneralError.invalidParameter(info: self.comp),
//                                 message:
//                    "Cannot append message without parent folder and this, account")
//                return
//            }
//            guard let cdFolder = self.retrieveFolderForAppend(
//                account: account, context: self.context) else {
//                    self.handleError(
//                        BackgroundError.GeneralError.invalidParameter(info: self.comp),
//                        message: "Cannot find sent folder for message to append")
//                    return
//            }
//            if cdFolder.folder().shouldNotAppendMessages {
//                // We are not supposed to append messages to this (probably virtual) mailbox.
//                // This is only for savety reasons, we should never come in here as messages
//                // should not be marked for appending in the first place.
//                // In case it turns out that there *Are* valid cases to reach this, we should
//                // also delete the triggering message to avoid that it is processed here on
//                // every sync loop.
//                Log.shared.errorAndCrash(component: #function,
//                                         errorString: "We should never come here.")
//                handleNextMessage()
//                return
//            }
//            guard let fn = cdFolder.name else {
//                self.handleError(BackgroundError.GeneralError.invalidParameter(info: self.comp),
//                                 message: "Need the name for the sent folder")
//                return
//            }
//            self.targetFolderName = fn
//        }
//    }
//
//    final func handleNextMessage() {
//        deleteLastExpungedMessage()
//
//        guard let (msg, ident, objID) = retrieveNextMessage() else {
//            markAsFinished()
//            return
//        }
//
//        lastHandledMessageObjectID = objID
////        determineTargetFolder(msgID: objID)
//        //BUFF:
//        // expunch
//    }
//
//    override func markAsFinished() {
//        syncDelegate = nil
//        super.markAsFinished()
//    }
}

//class UidPlusExpungeMailsSyncDelegate: DefaultImapSyncDelegate {
//    //BUFF:
//    public override func folderAppendCompleted(_ sync: ImapSync, notification: Notification?) {
//        (errorHandler as? AppendMailsOperationBase)?.handleNextMessage()
//    }
//
//    public override func folderAppendFailed(_ sync: ImapSync, notification: Notification?) {
//        (errorHandler as? AppendMailsOperationBase)?.addIMAPError(ImapSyncError.folderAppendFailed)
//        (errorHandler as? AppendMailsOperationBase)?.markAsFinished()
//    }
//}

