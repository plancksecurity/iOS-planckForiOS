//
//  AppendTrashMailsOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 06/02/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit
import CoreData

import MessageModel

/**
 Copies deleted messages to the trash folder, and marks them as copied, so they
 can be expunged.
 */
public class AppendTrashMailsOperation: AppendMailsOperationBase {
    let folderObjectID: NSManagedObjectID
    let syncTrashWithServer: Bool

    public init(parentName: String = #function, imapSyncData: ImapSyncData,
                errorContainer: ServiceErrorProtocol = ErrorContainer(), folder: CdFolder,
                syncTrashWithServer: Bool) {
        let trashFolderType = FolderType.trash
        self.folderObjectID = folder.objectID
        self.syncTrashWithServer = syncTrashWithServer
        super.init(
            parentName: parentName,
            appendFolderType: trashFolderType,
            imapSyncData: imapSyncData,
            errorContainer: errorContainer,
            encryptMode: .encryptToMySelf)
    }

    override func handleNextMessage() {
        // Power User
        if syncTrashWithServer {
            // If we are supposed to sync trash, the default implementation is fine
            super.handleNextMessage()
            return
        }
        // Non Power User
        guard
            let msg = nextCdMessage(),
            let context = msg.managedObjectContext else {
                self.markAsFinished()
                return
        }

        context.performAndWait {
            guard let cdAccount = context.object(with: imapSyncData.connectInfo.accountObjectID) as? CdAccount,
                let orig = msg.message() else {
                    Log.shared.errorAndCrash(component: #function, errorString: "IUhu__ ...")
                    markAsFinished()
                    return
            }

            let account = cdAccount.account()
            guard let trashFolder = Folder.by(account: account, folderType: .trash) else {
                Log.shared.errorAndCrash(component: #function, errorString: "No trash")
                self.markAsFinished()
                return
            }
            let newTrashMsg = Message(uuid: MessageID.generate(), uid: 0, parentFolder: trashFolder)
            newTrashMsg.attachments = orig.attachments
            newTrashMsg.bcc = orig.bcc
            newTrashMsg.cc = orig.cc
            newTrashMsg.from = orig.from
            newTrashMsg.longMessage = orig.longMessage
            newTrashMsg.longMessageFormatted = orig.longMessageFormatted
            newTrashMsg.pEpRatingInt = Int(PEP_rating_unencrypted.rawValue)
            newTrashMsg.sent = orig.sent
            newTrashMsg.shortMessage = orig.shortMessage
            newTrashMsg.to = orig.to
            newTrashMsg.save()

            msg.imap?.trashedStatus = .trashed
        }
        Record.saveAndWait()

        handleNextMessage()
    }

    override func retrieveNextMessage() -> (PEPMessageDict, PEPIdentity, NSManagedObjectID)? {
        var result: (PEPMessageDict, PEPIdentity, NSManagedObjectID)?
        context.performAndWait {
            guard let msg = nextCdMessage(),
                let cdIdent = msg.parent?.account?.identity else {
                    return
            }
            result = (msg.pEpMessageDict(), cdIdent.pEpIdentity(), msg.objectID)
        }
        return result
    }

    private func nextCdMessage() -> CdMessage? {
        var result: CdMessage? = nil
        context.performAndWait {
            guard let folder = self.context.object(with: self.folderObjectID) as? CdFolder else {
                return
            }
            let p = NSPredicate(
                format: "parent = %@ AND imap.localFlags.flagDeleted = true AND imap.trashedStatusRawValue = %d AND parent.account = %@",
                folder, Message.TrashedStatus.shouldBeTrashed.rawValue,
                imapSyncData.connectInfo.accountObjectID)

            result = CdMessage.first(predicate: p, in: self.context)
        }
        return result
    }

    override func markLastMessageAsFinished() {
        if let msgID = lastHandledMessageObjectID {
            context.performAndWait {
                if let obj = self.context.object(with: msgID) as? CdMessage {
                    let imap = obj.imapFields(context: self.context)
                    imap.trashedStatus = Message.TrashedStatus.trashed
                    obj.imap = imap
                    self.context.saveAndLogErrors()
                } else {



                    self.handleError(BackgroundError.GeneralError.invalidParameter(info:self.comp),
                                     message: "Cannot find message just stored in the sent folder")
                    return
                }
            }
        }
    }

    static func foldersWithTrashedMessages(context: NSManagedObjectContext) -> [CdFolder] {
        var result = [CdFolder]()
        context.performAndWait {
            let p = NSPredicate(
                format: "imap.localFlags.flagDeleted = true AND imap.trashedStatusRawValue = %d AND parent.folderTypeRawValue != %d",
                Message.TrashedStatus.shouldBeTrashed.rawValue, FolderType.trash.rawValue)
            let msgs = CdMessage.all(predicate: p, orderedBy: nil, in: context) as? [CdMessage] ?? []
            var folders = Set<CdFolder>()
            for m in msgs {
                if let p = m.parent {
                    folders.insert(p)
                }
            }
            result = folders.sorted() { f1, f2 in
                return f1.name ?? "" < f2.name ?? ""
            }
        }
        
        return result
    }
}
