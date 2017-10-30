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

public class AppendDraftMailsOperation: AppendMailsOperationBase {

    public init(parentName: String = #function, imapSyncData: ImapSyncData, errorContainer: ServiceErrorProtocol = ErrorContainer()) {
        let appendFolder = FolderType.drafts
        super.init(parentName: parentName, appendFolderType: appendFolder, imapSyncData: imapSyncData, errorContainer: errorContainer)
    }

    override func retrieveNextMessage() -> (PEPMessageDict, PEPIdentity, NSManagedObjectID)? {
        var msg: CdMessage?
        context.performAndWait {
            let p = NSPredicate(
                format: "uid = 0 and parent.folderTypeRawValue = %d and sendStatusRawValue = %d",
                FolderType.drafts.rawValue, SendStatus.none.rawValue)
            msg = CdMessage.first(predicate: p, in: self.context)
        }
        if let m = msg, let cdIdent = m.parent?.account?.identity {
            return (m.pEpMessage(), cdIdent.pEpIdentity(), m.objectID)
        }
        return nil
    }
}
