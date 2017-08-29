//
//  CreateFoldersOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 28/11/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit
import CoreData

import MessageModel

/**
 Tries to create all local folders on the server.
 */
open class CreateFoldersOperation: ImapSyncOperation {
    let accountID: NSManagedObjectID
    var account: CdAccount!
    var folderNamesToCreate = [String]()
    var syncDelegate: CreateFoldersSyncDelegate?

    public init(parentName: String = #function, errorContainer: ServiceErrorProtocol = ErrorContainer(),
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

        if let foldersSet = account.folders {
            for f in foldersSet {
                if let fol = f as? CdFolder {
                    if let fn = fol.name {
                        folderNamesToCreate.append(fn)
                    }
                }
            }
        }

        if folderNamesToCreate.count > 0 {
            syncDelegate = CreateFoldersSyncDelegate(errorHandler: self)
            imapSyncData.sync?.delegate = syncDelegate
            createNextFolder()
        } else {
            markAsFinished()
        }
    }

    func createNextFolder() {
        if !isCancelled, let fn = folderNamesToCreate.first {
            imapSyncData.sync?.createFolderWithName(fn)
            folderNamesToCreate.removeFirst()
        } else {
            markAsFinished()
        }
    }

    override func markAsFinished() {
        syncDelegate = nil
        super.markAsFinished()
    }
}

class CreateFoldersSyncDelegate: DefaultImapSyncDelegate {
    public override func folderCreateCompleted(_ sync: ImapSync, notification: Notification?) {
        (errorHandler as? CreateFoldersOperation)?.createNextFolder()
    }
}
