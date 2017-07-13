//
//  DeleteFolderOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 19/09/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import CoreData

import MessageModel

open class DeleteFolderOperation: ImapSyncOperation {
    var folderName: String
    let accountID: NSManagedObjectID
    var account: CdAccount!
    var syncDelegate: DeleteFolderSyncDelegate?

    public init(parentName: String? = nil, errorContainer: ServiceErrorProtocol = ErrorContainer(),
                imapSyncData: ImapSyncData, account: CdAccount,
                folderName: String) {
        self.accountID = account.objectID
        self.folderName = folderName
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
            self.account = self.privateMOC.object(with: self.accountID) as? CdAccount
            guard self.account != nil else {
                self.addError(Constants.errorCannotFindAccount(component: self.comp))
                self.markAsFinished()
                return
            }
            self.syncDelegate = DeleteFolderSyncDelegate(errorHandler: self)
            self.imapSyncData.sync?.delegate = self.syncDelegate
            self.imapSyncData.sync?.deleteFolderWithName(self.folderName)
        }
    }

    func deleteLocalFolderAndFinish() {
        privateMOC.perform() {
            if let folder = CdFolder.by(name: self.folderName, account: self.account) {
                self.privateMOC.delete(folder)
            }
            self.markAsFinished()
        }
    }

    override func markAsFinished() {
        syncDelegate = nil
        super.markAsFinished()
    }
}

class DeleteFolderSyncDelegate: DefaultImapSyncDelegate {
    public override func folderDeleteCompleted(_ sync: ImapSync, notification: Notification?) {
        (errorHandler as? DeleteFolderOperation)?.deleteLocalFolderAndFinish()
    }
}
