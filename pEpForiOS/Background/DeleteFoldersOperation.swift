//
//  DeleteFolderOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 19/09/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import CoreData

import MessageModel

open class DeleteFoldersOperation: ImapSyncOperation {
    let accountID: NSManagedObjectID
    var account: CdAccount!
    var folderNamesToDelete = [String]()
    var currentFolderName: String?
    var syncDelegate: DeleteFoldersSyncDelegate?

    public init(parentName: String? = nil, errorContainer: ServiceErrorProtocol = ErrorContainer(),
                imapSyncData: ImapSyncData, account: CdAccount) {
        self.accountID = account.objectID
        super.init(parentName: parentName, errorContainer: errorContainer,
                   imapSyncData: imapSyncData)
    }

    open override func main() {
        if !shouldRun() {
            return
        }

        if !checkImapSync() {
            return
        }

        privateMOC.perform() {
            self.mainInternal()
        }
    }

    func mainInternal() {
        account = privateMOC.object(with: accountID) as? CdAccount
        guard account != nil else {
            addError(Constants.errorCannotFindAccount(component: comp))
            markAsFinished()
            return
        }

        let p = NSPredicate(format: "shouldDelete = true and account = %@", account)
        if let folders = CdFolder.all(predicate: p) as? [CdFolder] {
            for f in folders {
                if let fn = f.name {
                    folderNamesToDelete.append(fn)
                }
            }
        }

        if let sync = imapSyncData.sync {
            syncDelegate = DeleteFoldersSyncDelegate(imapSyncOperation: self)
            sync.delegate = syncDelegate
            deleteNextRemoteFolder(sync: sync)
        }
    }

    func deleteNextRemoteFolder(sync: ImapSync) {
        if let fn = currentFolderName {
            privateMOC.performAndWait() {
                if let folder = CdFolder.by(name: fn, account: self.account) {
                    self.privateMOC.delete(folder)
                }
            }
        }
        if !self.isCancelled {
            if let fn = folderNamesToDelete.first {
                currentFolderName = fn
                imapSyncData.sync?.deleteFolderWithName(fn)
                folderNamesToDelete.removeFirst()
                return
            }
        }
        markAsFinished()
    }

    override func markAsFinished() {
        syncDelegate = nil
        super.markAsFinished()
    }
}

class DeleteFoldersSyncDelegate: DefaultImapSyncDelegate {
    public override func folderDeleteCompleted(_ sync: ImapSync, notification: Notification?) {
        (imapSyncOperation as? DeleteFoldersOperation)?.deleteNextRemoteFolder(sync: sync)
    }
}
