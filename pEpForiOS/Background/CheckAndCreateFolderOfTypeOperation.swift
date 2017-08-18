//
//  CheckAndCreateFolderOfTypeOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 15/09/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import CoreData

import MessageModel

/**
 Can be run before operations that operate on folders, like "save draft"
 (with a dependency), to make sure that folder does exist.
 */
open class CheckAndCreateFolderOfTypeOperation: ImapSyncOperation {
    let folderType: FolderType
    var folderName: String

    /**
     Used to keep track of attempts. First try to create top-level,
     after that try to create under "INBOX", then give up.
     */
    var numberOfFailures = 0

    var account: CdAccount?

    var syncDelegate: CheckAndCreateFolderOfTypeSyncDelegate?

    public init(parentName: String, errorContainer: ServiceErrorProtocol = ErrorContainer(),
                imapSyncData: ImapSyncData, account: CdAccount, folderType: FolderType) {
        self.folderType = folderType
        self.folderName = folderType.folderName()
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
            self.process(context: self.privateMOC)
        }
    }

    func process(context privateMOC: NSManagedObjectContext) {
        guard let account = Record.Context.default.object(
            with: imapSyncData.connectInfo.accountObjectID)
            as? CdAccount else {
                addError(Constants.errorCannotFindAccount(component: comp))
                markAsFinished()
                return
        }

        let folder = CdFolder.by(folderType: self.folderType, account: account)
        if folder == nil {
            syncDelegate = CheckAndCreateFolderOfTypeSyncDelegate(errorHandler: self)
            self.imapSyncData.sync?.delegate = syncDelegate
            if !self.isCancelled {
                self.imapSyncData.sync?.createFolderWithName(self.folderName)
            }
        } else {
            self.markAsFinished()
        }
    }

    override func markAsFinished() {
        syncDelegate = nil
        super.markAsFinished()
    }
}

class CheckAndCreateFolderOfTypeSyncDelegate: DefaultImapSyncDelegate {
    public override func folderCreateCompleted(_ sync: ImapSync, notification: Notification?) {
        guard let op = errorHandler as? CheckAndCreateFolderOfTypeOperation else {
            return
        }
        op.privateMOC.perform() {
            self.completed(context: op.privateMOC)
        }
    }

    func completed(context: NSManagedObjectContext) {
        guard let op = errorHandler as? CheckAndCreateFolderOfTypeOperation else {
            return
        }
        if let ac = op.account {
            let server = context.object(with: op.imapSyncData.connectInfo.serverObjectID)
                as? CdServer
            if CdFolder.insertOrUpdate(folderName: op.folderName,
                                       folderSeparator: server?.imapFolderSeparator,
                                       folderType: op.folderType,
                                       account: ac) == nil {
                op.addError(Constants.errorFolderCreateFailed(#function, name: op.folderName))
            } else {
                Record.saveAndWait(context: context)
            }
        }
        op.markAsFinished()
    }

    public override func folderCreateFailed(_ sync: ImapSync, notification: Notification?) {
        guard let op = errorHandler as? CheckAndCreateFolderOfTypeOperation else {
            return
        }
        op.privateMOC.perform() {
            self.tryAgain(context: op.privateMOC, sync: sync)
        }
    }

    func tryAgain(context: NSManagedObjectContext, sync: ImapSync) {
        guard let op = errorHandler as? CheckAndCreateFolderOfTypeOperation else {
            return
        }
        if !op.isCancelled {
            let server = context.object(with: op.imapSyncData.connectInfo.serverObjectID)
                as? CdServer
            if op.numberOfFailures == 0, let fs = server?.imapFolderSeparator {
                op.folderName = "INBOX\(fs)\(op.folderName)"
                sync.createFolderWithName(op.folderName)
                op.numberOfFailures += 1
                return
            }
            op.addError(Constants.errorFolderCreateFailed(#function, name: op.folderName))
            op.markAsFinished()
        }
    }
}
