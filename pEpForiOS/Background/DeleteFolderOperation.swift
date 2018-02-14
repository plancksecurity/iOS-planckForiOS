//
//  DeleteFolderOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 19/09/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import CoreData

import MessageModel

public class DeleteFolderOperation: ImapSyncOperation {
    var folderName: String
    let accountID: NSManagedObjectID
    var account: CdAccount!
    var syncDelegate: DeleteFolderSyncDelegate?

    public init(parentName: String = #function, errorContainer: ServiceErrorProtocol = ErrorContainer(),
                imapSyncData: ImapSyncData, account: CdAccount,
                folderName: String) {
        self.accountID = account.objectID
        self.folderName = folderName
        super.init(parentName: parentName, errorContainer: errorContainer,
                   imapSyncData: imapSyncData)
    }

    public override func main() {
        if !shouldRun() {
            markAsFinished()
            return
        }

        if !checkImapSync() {
            markAsFinished()
            return
        }

        privateMOC.perform() {
            self.account = self.privateMOC.object(with: self.accountID) as? CdAccount
            guard self.account != nil else {
                self.addError(BackgroundError.CoreDataError.couldNotFindAccount(info: self.comp))
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

    func handleBadResponse(sync: ImapSync, response: String?) {
        let msg = response ?? "Bad Response"
        Log.shared.errorComponent(#function,
                                  message: "The folder could not be deleted: \(msg)")
        self.markAsFinished()
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

    public override func badResponse(_ sync: ImapSync, response: String?) {
        (errorHandler as? DeleteFolderOperation)?.handleBadResponse(sync: sync, response: response)
    }
}
