//
//  CreateRequiredFoldersOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 01/03/17.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit
import CoreData

import MessageModel

/**
 Checks for needed folders, like "Drafts", and when they don't exist, create them
 both locally and remote.
 */
public class CreateRequiredFoldersOperation: ImapSyncOperation {
    private struct FolderToCreate {
        var folderName: String
        let folderSeparator: String?
        let folderType: FolderType
        let cdAccount: CdAccount
    }
    private struct CreationAttempt {
        var count = 0
        var folderToCreate: FolderToCreate?

        mutating func reset() {
            count = 0
            folderToCreate = nil
        }
    }
    private var currentAttempt = CreationAttempt()
    private var foldersToCreate = [FolderToCreate]()
    private var folderSeparator: String?
    private var syncDelegate: CreateRequiredFoldersSyncDelegate?
    
    public var numberOfFoldersCreated = 0

    public override func main() {
        if !checkImapSync() {
            markAsFinished()
            return
        }
        privateMOC.perform {
            self.process()
        }
    }

    private func process() {
        guard let account = privateMOC.object(with: imapSyncData.connectInfo.accountObjectID)
            as? CdAccount else {
                addError(BackgroundError.CoreDataError.couldNotFindAccount(info: comp))
                markAsFinished()
                return
        }

        assureLocalFoldersExist(for: account.account())

        for ft in FolderType.requiredTypes {
            if let cdF = CdFolder.by(folderType: ft, account: account) {
                if folderSeparator == nil {
                    folderSeparator = cdF.folderSeparatorAsString()
                }
            } else {
                let folderName = ft.folderName()
                foldersToCreate.append(
                    FolderToCreate(folderName: folderName, folderSeparator: folderSeparator,
                                   folderType: ft, cdAccount: account))
            }
        }

        if folderSeparator == nil {
            folderSeparator = CdFolder.folderSeparatorAsString(cdAccount: account)
        }

        if foldersToCreate.count > 0 {
            privateMOC.saveAndLogErrors()
            syncDelegate = CreateRequiredFoldersSyncDelegate(errorHandler: self)
            imapSyncData.sync?.delegate = syncDelegate
            createNextFolder()
        } else {
            markAsFinished()
        }
    }

    fileprivate func createNextFolder() {
        if let lastFolder = currentAttempt.folderToCreate {
            privateMOC.performAndWait {
                self.createLocal(folderToCreate: lastFolder, context: self.privateMOC)
            }
        }
        if !isCancelled, let folderToCreate = foldersToCreate.first {
            currentAttempt.reset()
            currentAttempt.folderToCreate = folderToCreate
            startFolderCreation(folderToCreate: folderToCreate)
            foldersToCreate.removeFirst()
        } else {
            markAsFinished()
        }
    }

    private func startFolderCreation(folderToCreate: FolderToCreate) {
        imapSyncData.sync?.createFolderWithName(folderToCreate.folderName)
    }

    private func createLocal(folderToCreate: FolderToCreate, context: NSManagedObjectContext) {
        let _ = CdFolder.insertOrUpdate(
            folderName: folderToCreate.folderName, folderSeparator: folderToCreate.folderSeparator,
            folderType: folderToCreate.folderType, account: folderToCreate.cdAccount)
        Record.saveAndWait(context: privateMOC)

    }

    fileprivate func createFolderAgain(potentialError: Error) {
        if currentAttempt.count == 0, var folderToCreate = currentAttempt.folderToCreate,
            let fs = folderSeparator {
            folderToCreate.folderName =
            "\(ImapSync.defaultImapInboxName)\(fs)\(folderToCreate.folderName)"
            currentAttempt.folderToCreate = folderToCreate
            currentAttempt.count += 1
            startFolderCreation(folderToCreate: folderToCreate)
        } else {
            currentAttempt.reset()
            addIMAPError(potentialError)
            markAsFinished()
        }
    }

    private func assureLocalFoldersExist(for account: Account) {
        if let _ = Folder.by(account: account, folderType: .outbox) {
            // Nothing to do. Outbox is currently the only existing local folder type
            return
        }
        let name = FolderType.outbox.folderName()
        let createe = Folder(name: name,
                             parent: nil,
                             account: account,
                             folderType: .outbox)
        createe.save()
    }

    override func markAsFinished() {
        syncDelegate = nil
        super.markAsFinished()
    }
}

class CreateRequiredFoldersSyncDelegate: DefaultImapSyncDelegate {
    public override func folderCreateCompleted(_ sync: ImapSync, notification: Notification?) {
        guard let op = errorHandler as? CreateRequiredFoldersOperation else {
            return
        }
        op.numberOfFoldersCreated += 1
        op.createNextFolder()
    }

    public override func folderCreateFailed(_ sync: ImapSync, notification: Notification?) {
        guard let op = errorHandler as? CreateRequiredFoldersOperation else {
            return
        }
        op.createFolderAgain(potentialError: ImapSyncError.illegalState(#function))
    }
}
