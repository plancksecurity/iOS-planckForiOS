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

    public init(parentName: String = #function, imapSyncData: ImapSyncData,
                errorContainer: ServiceErrorProtocol = ErrorContainer(), folder: CdFolder) {
        let trashFolderType = FolderType.trash
        self.folderObjectID = folder.objectID
        super.init(
            parentName: parentName,
            appendFolderType: trashFolderType,
            imapSyncData: imapSyncData,
            errorContainer: errorContainer)
    }

    override func retrieveNextMessage() -> (PEPMessageDict, PEPIdentity, NSManagedObjectID)? {
        var result: (PEPMessageDict, PEPIdentity, NSManagedObjectID)?
        context.performAndWait {
            guard let folder = self.context.object(with: self.folderObjectID) as? CdFolder else {
                return
            }
            let p = NSPredicate(
                format: "parent = %@ AND imap.localFlags.flagDeleted = true AND imap.trashedStatusRawValue = %d AND parent.account = %@",
                folder, Message.TrashedStatus.shouldBeTrashed.rawValue,
                imapSyncData.connectInfo.accountObjectID)

            if let msg = CdMessage.first(predicate: p, in: self.context),
                let cdIdent = msg.parent?.account?.identity {
                result = (msg.pEpMessage(), cdIdent.pEpIdentity(), msg.objectID)
            }
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
                    self.handleError(
                        Constants.errorInvalidParameter(self.comp),
                        message:
                        NSLocalizedString(
                            "Cannot find message just stored in the sent folder",
                            comment: "Background operation error message"))
                    return
                }
            }
        }
    }

    static func foldersWithTrashedMessages(context: NSManagedObjectContext) -> [CdFolder] {
        let p = NSPredicate(
            format: "imap.localFlags.flagDeleted = true and imap.trashedStatusRawValue = %d",
            Message.TrashedStatus.shouldBeTrashed.rawValue)
        let msgs = CdMessage.all(predicate: p, orderedBy: nil, in: context) as? [CdMessage] ?? []
        var folders = Set<CdFolder>()
        for m in msgs {
            if let p = m.parent {
                folders.insert(p)
            }
        }
        return folders.sorted() { f1, f2 in
            return f1.name ?? "" < f2.name ?? ""
        }
    }
}
