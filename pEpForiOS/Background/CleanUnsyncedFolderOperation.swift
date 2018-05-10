//
//  CleanUnsyncedFolderOperation.swift
//  pEp
//
//  Created by Andreas Buff on 07.03.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import CoreData
import MessageModel

/// This operation removes trashed mails in the local store.
/// Mails are considered as trashed if:
/// - parent == trash && isDeleted == true
/// OR
/// - parent != trash && trashed status == trashed
/// This operation MUST NOT be used for folders that are synced with the server!
class CleanUnsyncedFolderOperation: ConcurrentBaseOperation {
    let cdAccountObejctId: NSManagedObjectID
    let folderName: String

    init(parentName: String = #function,
                  errorContainer: ServiceErrorProtocol = ErrorContainer(),
                  cdAccountObejctId: NSManagedObjectID,
                  folderName: String) {
        self.cdAccountObejctId = cdAccountObejctId
        self.folderName = folderName
        super.init(parentName: parentName, errorContainer: errorContainer)
    }

    override public func main() {
        let context = privateMOC
        context.perform() {
            self.process(context: context)
        }
    }

    private func process(context: NSManagedObjectContext) {
        guard
            let cdAccount = context.object(with: cdAccountObejctId) as? CdAccount,
            let cdFolder = CdFolder.by(name: folderName, account: cdAccount) else {
                Log.shared.errorAndCrash(component: #function, errorString: "No account")
                handleError(BackgroundError.CoreDataError.couldNotFindAccount(info: nil))
                return
        }

        if cdFolder.folderType == .trash {
            deleteAllMarkedDeleted(in: cdFolder, cdAccount: cdAccount, context: context)
        } else {
            deleteAllTrashedStatusTrashed(in: cdFolder, cdAccount: cdAccount, context: context)
        }
        markAsFinished()
    }

    /// Removes all messages from the local store that have trashedStatus == trashed.
    private func deleteAllTrashedStatusTrashed(in cdFolder: CdFolder,
                                               cdAccount: CdAccount,
                                               context: NSManagedObjectContext) {
        let predicateAllTrashed =
            NSPredicate(format:
                "parent.account = %@ AND parent = %@ AND imap.trashedStatusRawValue = %d",
                        cdAccount, cdFolder, Message.TrashedStatus.trashed.rawValue)
        guard let msgToDelete = CdMessage.all(predicate: predicateAllTrashed) as? [CdMessage] else {
            // nothing todo
            return
        }
        for msg in msgToDelete {
            msg.deleteAndInformDelegate(context: context)
        }
    }

    /// Removes messages from the local store that are flagged deleted.
    private func deleteAllMarkedDeleted(in cdFolder: CdFolder,
                                               cdAccount: CdAccount,
                                               context: NSManagedObjectContext) {
        let predicateDeletedInTrashFolder =
            NSPredicate(format:
                "parent.account = %@ AND parent = %@ AND imap.localFlags.flagDeleted == YES ",
                        cdAccount, cdFolder)
        guard let msgsToDelete = CdMessage.all(predicate: predicateDeletedInTrashFolder) as? [CdMessage] else {
            // nothing todo
            return
        }
        for msg in msgsToDelete {
            msg.deleteAndInformDelegate(context: context)
        }
    }
}
