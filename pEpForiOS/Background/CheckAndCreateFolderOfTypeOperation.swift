//
//  CheckAndCreateFolderOfTypeOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 15/09/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit
import CoreData

/**
 Can be run before operations that operate on folders, like "save draft"
 (with a dependency), to make sure that folder does exist.
 */
open class CheckAndCreateFolderOfTypeOperation: ConcurrentBaseOperation {
    let comp = "CheckAndCreateFolderOfTypeOperation"
    let folderType: FolderType
    let accountEmail: String
    let connectInfo: ConnectInfo
    let connectionManager: ConnectionManager
    var folderName: String
    var imapSync: ImapSync!

    /**
     Used to keep track of attempts. First try to create top-level,
     after that try to create under "INBOX", then give up.
     */
    var numberOfFailures = 0

    var folderSeparator: String?

    public init(account: IAccount, folderType: FolderType,
                connectionManager: ConnectionManager, coreDataUtil: ICoreDataUtil) {
        self.accountEmail = account.email
        self.connectInfo = account.connectInfo
        self.folderType = folderType
        self.folderName = folderType.folderName()
        self.connectionManager = connectionManager
        super.init(coreDataUtil: coreDataUtil)
    }

    open override func main() {
        privateMOC.perform() {
            let folder = self.model.folderByType(self.folderType, email: self.accountEmail)
            if folder == nil {
                guard let account = self.model.accountByEmail(self.accountEmail) else {
                    self.addError(Constants.errorCannotFindAccountForEmail(
                        self.comp, email: self.accountEmail))
                    self.markAsFinished()
                    return
                }
                self.folderSeparator = account.folderSeparator
                self.imapSync = self.connectionManager.emailSyncConnection(self.connectInfo)
                self.imapSync.delegate = self
                self.imapSync.start()
            } else {
                self.markAsFinished()
            }
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
            if self.model.insertOrUpdateFolderName(
                self.folderName, folderSeparator: self.folderSeparator,
                accountEmail: self.accountEmail) == nil {
                self.addError(Constants.errorFolderCreateFailed(self.comp,
                    name: self.folderName))
            }
            self.model.save()
            self.markAsFinished()
        }
    }

    public func folderCreateFailed(_ sync: ImapSync, notification: Notification?) {
        if !self.isCancelled {
            if numberOfFailures == 0 {
                if let fs = folderSeparator {
                    self.folderName = "INBOX\(fs)\(folderName)"
                    sync.createFolderWithName(folderName)
                    numberOfFailures += 1
                    return
                }
            }
        }
        addError(Constants.errorFolderCreateFailed(comp, name: folderName))
        markAsFinished()
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
