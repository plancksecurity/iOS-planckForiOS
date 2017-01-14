//
//  AppendDraftMailsOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 14/01/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit
import CoreData

import MessageModel

open class AppendDraftMailsOperation: AppendMailsOperation {
    override func retrieveNextMessage() -> (PEPMessage, PEPIdentity, NSManagedObjectID)? {
        var msg: CdMessage?
        context.performAndWait {
            let p = NSPredicate(
                format: "uid = 0 and parent.folderType = %d and sendStatus = %d",
                FolderType.drafts.rawValue, SendStatus.none.rawValue)
            msg = CdMessage.first(with: p, in: self.context)
        }
        if let m = msg, let cdIdent = m.parent?.account?.identity {
            return (m.pEpMessage(), cdIdent.pEpIdentity(), m.objectID)
        }
        return nil
    }

    override func retrieveFolderForAppend(
        account: CdAccount, context: NSManagedObjectContext) -> CdFolder? {
        return CdFolder.by(folderType: .drafts, account: account, context: context)
    }
}
