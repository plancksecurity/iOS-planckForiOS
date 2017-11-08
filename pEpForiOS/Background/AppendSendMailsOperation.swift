//
//  AppendSendMailsOperation.swift
//  pEpForiOS
//
//  Created by Andreas Buff on 30.08.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import MessageModel
import CoreData

/**
 Stores SMTPed mails in the sent folder.
 */
public class AppendSendMailsOperation: AppendMailsOperationBase {
    public init(parentName: String = #function, imapSyncData: ImapSyncData, errorContainer: ServiceErrorProtocol = ErrorContainer()) {
        let appendFolder = FolderType.sent
        super.init(parentName: parentName, appendFolderType: appendFolder, imapSyncData: imapSyncData, errorContainer: errorContainer)
    }

    override func retrieveNextMessage() -> (PEPMessageDict, PEPIdentity, NSManagedObjectID)? {
        var msg: CdMessage?
        context.performAndWait {
            let p = NSPredicate(
                format: "uid = 0 and parent.folderTypeRawValue = %d and sendStatusRawValue = %d AND parent.account = %@",
                self.targetFolderType.rawValue, SendStatus.smtpDone.rawValue,
                imapSyncData.connectInfo.accountObjectID)
            msg = CdMessage.first(predicate: p, in: self.context)
        }
        if let m = msg, let cdIdent = m.parent?.account?.identity {
            return (m.pEpMessage(), cdIdent.pEpIdentity(), m.objectID)
        }
        return nil
    }
}
