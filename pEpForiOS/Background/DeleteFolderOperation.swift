//
//  DeleteFolderOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 19/09/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import CoreData
import pEpIOSToolbox
import MessageModel

public class DeleteFolderOperation: ImapSyncOperation {
    var folderName: String
    let accountID: NSManagedObjectID
    var account: CdAccount!
    var syncDelegate: DeleteFolderSyncDelegate?

    init(parentName: String = #function, errorContainer: ServiceErrorProtocol = ErrorContainer(),
                imapSyncData: ImapSyncData, account: CdAccount,
                folderName: String) {
        self.accountID = account.objectID
        self.folderName = folderName
        super.init(parentName: parentName, errorContainer: errorContainer,
                   imapSyncData: imapSyncData)
    }

    public override func main() {
        if !checkImapSync() {
            markAsFinished()
            return
        }

        privateMOC.perform() { [weak self] in
            guard let me = self else {
                Logger.backendLogger.lostMySelf()
                return
            }
            me.account = me.privateMOC.object(with: me.accountID) as? CdAccount
            guard me.account != nil else {
                me.addError(BackgroundError.CoreDataError.couldNotFindAccount(info: me.comp))
                me.markAsFinished()
                return
            }
            me.syncDelegate = DeleteFolderSyncDelegate(errorHandler: me)
            me.imapSyncData.sync?.delegate = me.syncDelegate
            me.imapSyncData.sync?.deleteFolderWithName(me.folderName)
        }
    }

    func deleteLocalFolderAndFinish() {
        privateMOC.perform { [weak self] in
            guard let me = self else {
                Logger.backendLogger.lostMySelf()
                return
            }
            if let folder = CdFolder.by(name: me.folderName, account: me.account) {
                me.privateMOC.delete(folder)
                Record.saveAndWait(context: me.privateMOC)
            }
            me.markAsFinished()
        }
    }

    func handleBadResponse(sync: ImapSync, response: String?) {
        let msg = response ?? "Bad Response"
        Logger.backendLogger.error("The folder could not be deleted: %{public}@", msg)
        self.markAsFinished()
    }

    override open func markAsFinished() {
        syncDelegate = nil
        super.markAsFinished()
    }
}

class DeleteFolderSyncDelegate: DefaultImapSyncDelegate {
    override open func folderDeleteCompleted(_ sync: ImapSync, notification: Notification?) {
        (errorHandler as? DeleteFolderOperation)?.deleteLocalFolderAndFinish()
    }

    override open func badResponse(_ sync: ImapSync, response: String?) {
        (errorHandler as? DeleteFolderOperation)?.handleBadResponse(sync: sync, response: response)
    }
}
