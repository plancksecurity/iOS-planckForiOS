//
//  TrashMessages.swift
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
class TrashMessages: AppendMailsOperation {
    override func retrieveNextMessage() -> (PEPMessage, PEPIdentity, NSManagedObjectID)? {
        var msg: CdMessage?
        context.performAndWait {
            let p = NSPredicate(
                format: "uid = 0 and parent.folderType = %d and imap.flagDeleted = true",
                FolderType.drafts.rawValue)
            msg = CdMessage.first(predicate: p, in: self.context)
        }
        if let m = msg, let cdIdent = m.parent?.account?.identity {
            return (m.pEpMessage(), cdIdent.pEpIdentity(), m.objectID)
        }
        return nil
    }

    /**
     - Returns: The trash folder, or nil, if that does not exist.
     */
    override func retrieveFolderForAppend(
        account: CdAccount, context: NSManagedObjectContext) -> CdFolder? {
        return CdFolder.by(folderType: .trash, account: account, context: context)
    }
}
