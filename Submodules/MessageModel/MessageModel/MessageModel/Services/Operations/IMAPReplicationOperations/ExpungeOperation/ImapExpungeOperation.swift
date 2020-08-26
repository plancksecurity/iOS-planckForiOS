//
//  ImapExpungeOperation.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 12.12.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation
import CoreData

/// When run, queries for folders that contain messages that are flagged with (IMAP) \Delete
/// both locally and on the server, and for each of those folders spawns a
/// `ExpungeInImapFolderOperation` (via putting it into its `backgroundQueue`)
/// that will handle the actual EXPUNGE (which is folder based).
class ImapExpungeOperation: ConcurrentBaseOperation {
    var imapConnection: ImapConnectionProtocol

    required init(parentName: String = #function,
                  context: NSManagedObjectContext? = nil,
                  errorContainer: ErrorContainerProtocol = ErrorPropagator(),
                  imapConnection: ImapConnectionProtocol) {
        self.imapConnection = imapConnection
        super.init(parentName: parentName,
                   context: context,
                   errorContainer: errorContainer)
    }

    public override func main() {
        scheduleOperations()
        waitForBackgroundTasksAndFinish()
    }

    private func scheduleOperations() {
        privateMOC.performAndWait { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }

            guard let cdAccount = me.imapConnection.cdAccount(moc: privateMOC) else {
                me.addError(BackgroundError.CoreDataError.couldNotFindAccount(
                    info: me.comp))
                me.waitForBackgroundTasksAndFinish()
                return
            }

            let pImapDeletedLocally = NSPredicate(
                format: "%K = %d AND %K = %@",
                RelationshipKeyPath.cdMessage_imap_localFlags_flagDeleted,
                true,
                RelationshipKeyPath.cdMessage_parent_account,
                cdAccount)

            let pImapDeletedOnServer = NSPredicate(
                format: "%K = %d AND %K = %@",
                RelationshipKeyPath.cdMessage_imap_serverFlags_flagDeleted,
                true,
                RelationshipKeyPath.cdMessage_parent_account,
                cdAccount)

            let pImapDeleted = NSCompoundPredicate(
                andPredicateWithSubpredicates: [pImapDeletedLocally, pImapDeletedOnServer])

            let cdMsgs = CdMessage.all(predicate: pImapDeleted,
                                       in: privateMOC) as? [CdMessage] ?? []
            let allCdFolders = cdMsgs.compactMap { $0.parent }
            let uniqueCdFolders = Set(allCdFolders)

            for cdFolder in uniqueCdFolders {
                if let foldername = cdFolder.name {
                    let op = ExpungeInImapFolderOperation(errorContainer: errorContainer,
                                                          imapConnection: imapConnection,
                                                          folderName: foldername)
                    backgroundQueue.addOperation(op)
                }
            }
        }
    }
}
