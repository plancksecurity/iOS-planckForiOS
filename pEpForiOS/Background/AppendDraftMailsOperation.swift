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
    public init(
        parentName: String = #function, imapSyncData: ImapSyncData,
        errorContainer: ServiceErrorProtocol = ErrorContainer()) {
        let appendFolder = FolderType.drafts
        super.init(parentName: parentName, appendFolderType: appendFolder,
                   imapSyncData: imapSyncData, errorContainer: errorContainer,
                   encryptMode: .encryptToMySelf)
    }

    override func retrieveNextMessage() -> (PEPMessageDict, PEPIdentity, NSManagedObjectID)? {
        var result: (PEPMessageDict, PEPIdentity, NSManagedObjectID)? = nil
        context.performAndWait {
            let p = NSPredicate(
                format: "uid = 0 AND parent.folderTypeRawValue = %d AND sendStatusRawValue = %d AND parent.account = %@",
                FolderType.drafts.rawValue, SendStatus.none.rawValue,
                imapSyncData.connectInfo.accountObjectID)
            let msg = CdMessage.first(predicate: p, in: self.context)
            if let m = msg, let cdIdent = m.parent?.account?.identity {
                result = (m.pEpMessageDict(), cdIdent.pEpIdentity(), m.objectID)
            }
        }
        
        return result
    }
}
