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
    public init(parentName: String = #function,
                imapSyncData: ImapSyncData,
                errorContainer: ServiceErrorProtocol = ErrorContainer()) {
        let appendFolder = FolderType.sent
        super.init(parentName: parentName,
                   appendFolderType: appendFolder,
                   imapSyncData: imapSyncData,
                   errorContainer: errorContainer)
    }

    override func retrieveNextMessage() -> (PEPMessageDict, PEPIdentity, NSManagedObjectID)? {
        var result:(PEPMessageDict, PEPIdentity, NSManagedObjectID)? = nil
        privateMOC.performAndWait {
            let p = NSPredicate(
                format: "uid = 0 and parent.folderTypeRawValue = %d and sendStatusRawValue = %d AND parent.account = %@",
                self.targetFolderType.rawValue, SendStatus.smtpDone.rawValue,
                imapSyncData.connectInfo.accountObjectID)
            guard
                let msg = CdMessage.first(predicate: p, in: self.privateMOC),
                let cdIdent = msg.parent?.account?.identity,
                let folder = msg.parent?.folder() else {
                    result = nil
                    return
            }

            if folder.shouldNotAppendMessages {
                // For this folder the server appends send mails.
                // To avoid the current msg is processed here on every sync loop, we delete it.
                // That should be save as the message has been send successfully
                // (SendStatus.smtpDone) and the server is responsible for appending sent mails.
                msg.delete()
                Record.saveAndWait(context: privateMOC)
                // Recursivly get the next message.
                result = retrieveNextMessage()
                return
            }
            result = (msg.pEpMessageDict(), cdIdent.pEpIdentity(), msg.objectID)
        }
        return result
    }
}
