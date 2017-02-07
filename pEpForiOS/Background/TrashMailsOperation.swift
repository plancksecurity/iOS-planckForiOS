//
//  TrashMailsOperation.swift
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
open class TrashMailsOperation: AppendMailsOperation {
    let folderObjectID: NSManagedObjectID

    public init(parentName: String? = nil, imapSyncData: ImapSyncData,
                errorContainer: ServiceErrorProtocol = ErrorContainer(), folder: CdFolder) {
        self.folderObjectID = folder.objectID
        super.init(
            parentName: parentName, imapSyncData: imapSyncData, errorContainer: errorContainer)
    }

    override func retrieveNextMessage() -> (PEPMessage, PEPIdentity, NSManagedObjectID)? {
        var result: (PEPMessage, PEPIdentity, NSManagedObjectID)?
        context.performAndWait {
            guard let folder = self.context.object(with: self.folderObjectID) as? CdFolder else {
                return
            }
            let p = NSPredicate(
                format: "parent = %@ and imap.flagDeleted = true and imap.trashedStatus = %d",
                folder, TrashedStatus.shouldBeTrashed.rawValue)
            if let msg = CdMessage.first(predicate: p, in: self.context),
                let cdIdent = msg.parent?.account?.identity {
                result = (msg.pEpMessage(), cdIdent.pEpIdentity(), msg.objectID)
            }
        }
        return result
    }

    /**
     - Returns: The trash folder, or nil, if that does not exist.
     */
    override func retrieveFolderForAppend(
        account: CdAccount, context: NSManagedObjectContext) -> CdFolder? {
        return CdFolder.by(folderType: .trash, account: account, context: context)
    }

    override func markLastMessageAsFinished() {
        if let msgID = lastHandledMessageObjectID {
            context.performAndWait {
                if let obj = self.context.object(with: msgID) as? CdMessage {
                    let imap = obj.imap ?? CdImapFields.create(context: self.context)
                    imap.trashedStatus = TrashedStatus.trashed.rawValue
                    obj.imap = imap
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

    public static func foldersWithTrashedMessages(context: NSManagedObjectContext) -> [CdFolder] {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: CdMessage.entityName)
        request.resultType = .managedObjectResultType
        request.returnsDistinctResults = true
        request.propertiesToFetch = ["parent"]
        request.predicate = NSPredicate(
            format: "imap.flagDeleted = true and imap.trashedStatus = %d",
            TrashedStatus.shouldBeTrashed.rawValue)
        do {
            if let folders = try context.fetch(request) as? [CdMessage] {
                Log.warn(component: #function, content: "Have object \(folders)")
                for o in folders {
                    Log.warn(component: #function, content: "Have object \(o)")
                }
                return []
            }
        } catch let err as NSError {
            Log.error(component: #function, error: err)
        }
        return []
    }
}
