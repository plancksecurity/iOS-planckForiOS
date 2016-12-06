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
open class CheckAndCreateFolderOfTypeOperation: ConcurrentBaseOperation {
    let folderType: FolderType
    let connectInfo: EmailConnectInfo
    let connectionManager: ImapConnectionManagerProtocol
    var folderName: String
    var imapSync: ImapSync!

    /**
     Used to keep track of attempts. First try to create top-level,
     after that try to create under "INBOX", then give up.
     */
    var numberOfFailures = 0

    var account: CdAccount?

    public init(connectInfo: EmailConnectInfo, account: CdAccount,
                folderType: FolderType, connectionManager: ImapConnectionManagerProtocol) {
        self.connectInfo = connectInfo
        self.folderType = folderType
        self.folderName = folderType.folderName()
        self.connectionManager = connectionManager
    }

    open override func main() {
        privateMOC.perform() {
            self.process(context: self.privateMOC)
        }
    }

    func process(context privateMOC: NSManagedObjectContext) {
        guard let account = Record.Context.default.object(with: connectInfo.accountObjectID)
            as? CdAccount else {
                errors.append(Constants.errorCannotFindAccount(component: comp))
                markAsFinished()
                return
        }

        let folder = CdFolder.by(folderType: self.folderType, account: account)
        if folder == nil {
            self.imapSync = self.connectionManager.imapConnection(connectInfo: self.connectInfo)

            if self.imapSync == nil {
                self.addError(Constants.errorImapInvalidConnection(component: self.comp))
                self.markAsFinished()
                return
            }

            self.imapSync.delegate = self
            self.imapSync.start()
        } else {
            self.markAsFinished()
        }
    }
}

extension CheckAndCreateFolderOfTypeOperation: ImapSyncDelegate {
    public func authenticationCompleted(_ sync: ImapSync, notification: Notification?) {
        if !self.isCancelled {
            sync.createFolderWithName(folderName)
        }
    }

    public func authenticationFailed(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorAuthenticationFailed(comp))
        markAsFinished()
    }

    public func connectionLost(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorConnectionLost(comp))
        markAsFinished()
    }

    public func connectionTerminated(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorConnectionTerminated(comp))
        markAsFinished()
    }

    public func connectionTimedOut(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorConnectionTimeout(comp))
        markAsFinished()
    }

    public func folderPrefetchCompleted(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorIllegalState(comp, stateName: "folderPrefetchCompleted"))
        markAsFinished()
    }

    public func folderSyncCompleted(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorIllegalState(comp, stateName: "folderSyncCompleted"))
        markAsFinished()
    }

    public func messageChanged(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorIllegalState(comp, stateName: "messageChanged"))
        markAsFinished()
    }

    public func messagePrefetchCompleted(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorIllegalState(comp, stateName: "messagePrefetchCompleted"))
        markAsFinished()
    }

    public func folderOpenCompleted(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorIllegalState(comp, stateName: "folderOpenCompleted"))
        markAsFinished()
    }

    public func folderOpenFailed(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorIllegalState(comp, stateName: "folderOpenFailed"))
        markAsFinished()
    }

    public func folderStatusCompleted(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorIllegalState(comp, stateName: "folderStatusCompleted"))
        markAsFinished()
    }

    public func folderListCompleted(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorIllegalState(comp, stateName: "folderListCompleted"))
        markAsFinished()
    }

    public func folderNameParsed(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorIllegalState(comp, stateName: "folderNameParsed"))
        markAsFinished()
    }

    public func folderAppendCompleted(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorIllegalState(comp, stateName: "folderAppendCompleted"))
        markAsFinished()
    }

    public func folderAppendFailed(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorIllegalState(comp, stateName: "folderAppendFailed"))
        markAsFinished()
    }

    public func messageStoreCompleted(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorIllegalState(comp, stateName: "messageStoreCompleted"))
        markAsFinished()
    }

    public func messageStoreFailed(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorIllegalState(comp, stateName: "messageStoreFailed"))
        markAsFinished()
    }

    public func folderCreateCompleted(_ sync: ImapSync, notification: Notification?) {
        privateMOC.perform() {
            self.completed(context: self.privateMOC)
        }
    }

    func completed(context: NSManagedObjectContext) {
        if let ac = account {
            let server = context.object(with: connectInfo.serverObjectID) as? CdServer
            if CdFolder.insertOrUpdate(folderName: folderName,
                                       folderSeparator: server?.imapFolderSeparator,
                                       account: ac) == nil {
                self.addError(Constants.errorFolderCreateFailed(comp, name: folderName))
            } else {
                Record.saveAndWait(context: context)
            }
        }
        markAsFinished()
    }

    public func folderCreateFailed(_ sync: ImapSync, notification: Notification?) {
        privateMOC.perform() {
            self.tryAgain(context: self.privateMOC, sync: sync)
        }
    }

    func tryAgain(context: NSManagedObjectContext, sync: ImapSync) {
        if !isCancelled {
            let server = context.object(with: connectInfo.serverObjectID) as? CdServer
            if numberOfFailures == 0, let fs = server?.imapFolderSeparator {
                folderName = "INBOX\(fs)\(folderName)"
                sync.createFolderWithName(folderName)
                numberOfFailures += 1
                return
            }
            addError(Constants.errorFolderCreateFailed(comp, name: folderName))
            markAsFinished()
        }
    }

    public func folderDeleteCompleted(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorIllegalState(comp, stateName: "folderDeleteCompleted"))
        markAsFinished()
    }

    public func folderDeleteFailed(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorIllegalState(comp, stateName: "folderDeleteFailed"))
        markAsFinished()
    }

    public func actionFailed(_ sync: ImapSync, error: NSError) {
        addError(error)
        markAsFinished()
    }
}
