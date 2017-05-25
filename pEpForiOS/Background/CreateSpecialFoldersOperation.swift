//
//  CreateSpecialFoldersOperation.swift
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
open class CreateSpecialFoldersOperation: ImapSyncOperation {
    struct FolderToCreate {
        var folderName: String
        let folderType: FolderType
        let cdAccount: CdAccount
    }

    struct CreationAttempt {
        var count = 0
        var folderToCreate: FolderToCreate?

        mutating func reset() {
            count = 0
            folderToCreate = nil
        }
    }
    var currentAttempt = CreationAttempt()

    var foldersToCreate = [FolderToCreate]()
    public var numberOfFoldersCreated = 0
    var folderSeparator: String?

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
        guard let theAccount = privateMOC.object(with: imapSyncData.connectInfo.accountObjectID)
            as? CdAccount else {
                addError(Constants.errorCannotFindAccount(component: comp))
                markAsFinished()
                return
        }

        for ft in FolderType.neededFolderTypes {
            if let cdF = CdFolder.by(folderType: ft, account: theAccount) {
                if folderSeparator == nil {
                    folderSeparator = cdF.folderSeparatorAsString()
                }
            } else {
                let folderName = ft.folderName()
                foldersToCreate.append(
                    FolderToCreate(folderName: folderName, folderType: ft, cdAccount: theAccount))
            }
        }

        if folderSeparator == nil {
            folderSeparator = CdFolder.folderSeparatorAsString(cdAccount: theAccount)
        }

        if foldersToCreate.count > 0 {
            Record.saveAndWait(context: privateMOC)
            imapSyncData.sync?.delegate = self
            createNextFolder()
        } else {
            markAsFinished()
        }
    }

    func createNextFolder() {
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

    func startFolderCreation(folderToCreate: FolderToCreate) {
        imapSyncData.sync?.createFolderWithName(folderToCreate.folderName)
    }

    func createLocal(folderToCreate: FolderToCreate, context: NSManagedObjectContext) {
        let cdFolder = CdFolder.create(context: context)
        cdFolder.uuid = MessageID.generate()
        cdFolder.name = folderToCreate.folderName
        cdFolder.account = folderToCreate.cdAccount
        cdFolder.folderType = folderToCreate.folderType.rawValue
        Record.saveAndWait(context: context)
    }

    func createFolderAgain(potentialError: NSError) {
        if currentAttempt.count == 0, var folderToCreate = currentAttempt.folderToCreate,
            let fs = folderSeparator {
            folderToCreate.folderName =
            "\(ImapSync.defaultImapInboxName)\(fs)\(folderToCreate.folderName)"
            currentAttempt.folderToCreate = folderToCreate
            currentAttempt.count += 1
            startFolderCreation(folderToCreate: folderToCreate)
        } else {
            currentAttempt.reset()
            addError(potentialError)
            markAsFinished()
        }
    }
}

extension CreateSpecialFoldersOperation: ImapSyncDelegate {
    public func authenticationCompleted(_ sync: ImapSync, notification: Notification?) {
        addIMAPError(Constants.errorIllegalState(comp, stateName: "authenticationCompleted"))
        markAsFinished()
    }

    public func authenticationFailed(_ sync: ImapSync, notification: Notification?) {
        addIMAPError(Constants.errorAuthenticationFailed(comp))
        markAsFinished()
    }

    public func connectionLost(_ sync: ImapSync, notification: Notification?) {
        addIMAPError(Constants.errorConnectionLost(comp))
        markAsFinished()
    }

    public func connectionTerminated(_ sync: ImapSync, notification: Notification?) {
        addIMAPError(Constants.errorConnectionTerminated(comp))
        markAsFinished()
    }

    public func connectionTimedOut(_ sync: ImapSync, notification: Notification?) {
        addIMAPError(Constants.errorConnectionTimeout(comp))
        markAsFinished()
    }

    public func folderPrefetchCompleted(_ sync: ImapSync, notification: Notification?) {
        addIMAPError(Constants.errorIllegalState(comp, stateName: "folderPrefetchCompleted"))
        markAsFinished()
    }

    public func folderSyncCompleted(_ sync: ImapSync, notification: Notification?) {
        addIMAPError(Constants.errorIllegalState(comp, stateName: "folderSyncCompleted"))
        markAsFinished()
    }

    public func folderSyncFailed(_ sync: ImapSync, notification: Notification?) {
        addIMAPError(Constants.errorIllegalState(comp, stateName: "folderSyncFailed"))
        markAsFinished()
    }

    public func messageChanged(_ sync: ImapSync, notification: Notification?) {
        addIMAPError(Constants.errorIllegalState(comp, stateName: "messageChanged"))
        markAsFinished()
    }

    public func messagePrefetchCompleted(_ sync: ImapSync, notification: Notification?) {
        addIMAPError(Constants.errorIllegalState(comp, stateName: "messagePrefetchCompleted"))
        markAsFinished()
    }

    public func folderOpenCompleted(_ sync: ImapSync, notification: Notification?) {
        addIMAPError(Constants.errorIllegalState(comp, stateName: "folderOpenCompleted"))
        markAsFinished()
    }

    public func folderOpenFailed(_ sync: ImapSync, notification: Notification?) {
        addIMAPError(Constants.errorIllegalState(comp, stateName: "folderOpenFailed"))
        markAsFinished()
    }

    public func folderStatusCompleted(_ sync: ImapSync, notification: Notification?) {
        addIMAPError(Constants.errorIllegalState(comp, stateName: "folderStatusCompleted"))
        markAsFinished()
    }

    public func folderListCompleted(_ sync: ImapSync, notification: Notification?) {
        addIMAPError(Constants.errorIllegalState(comp, stateName: "folderListCompleted"))
        markAsFinished()
    }

    public func folderNameParsed(_ sync: ImapSync, notification: Notification?) {
        addIMAPError(Constants.errorIllegalState(comp, stateName: "folderNameParsed"))
        markAsFinished()
    }

    public func folderAppendCompleted(_ sync: ImapSync, notification: Notification?) {
        addIMAPError(Constants.errorIllegalState(comp, stateName: "folderAppendCompleted"))
        markAsFinished()
    }

    public func folderAppendFailed(_ sync: ImapSync, notification: Notification?) {
        addIMAPError(Constants.errorIllegalState(comp, stateName: "folderAppendFailed"))
        markAsFinished()
    }

    public func messageStoreCompleted(_ sync: ImapSync, notification: Notification?) {
        addIMAPError(Constants.errorIllegalState(comp, stateName: "messageStoreCompleted"))
        markAsFinished()
    }

    public func messageStoreFailed(_ sync: ImapSync, notification: Notification?) {
        addIMAPError(Constants.errorIllegalState(comp, stateName: "messageStoreFailed"))
        markAsFinished()
    }

    public func folderCreateCompleted(_ sync: ImapSync, notification: Notification?) {
        numberOfFoldersCreated += 1
        createNextFolder()
    }

    public func folderCreateFailed(_ sync: ImapSync, notification: Notification?) {
        createFolderAgain(
            potentialError: Constants.errorIllegalState(comp, stateName: "folderCreateFailed"))
    }

    public func folderDeleteCompleted(_ sync: ImapSync, notification: Notification?) {
        addIMAPError(Constants.errorIllegalState(comp, stateName: "folderDeleteCompleted"))
        markAsFinished()
    }

    public func folderDeleteFailed(_ sync: ImapSync, notification: Notification?) {
        addIMAPError(Constants.errorIllegalState(comp, stateName: "folderDeleteFailed"))
        markAsFinished()
    }

    public func badResponse(_ sync: ImapSync, response: String?) {
        addIMAPError(ImapSyncError.badResponse(response))
        markAsFinished()
    }
}
