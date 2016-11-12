//
//  FetchFoldersOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 03/05/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation
import CoreData

import MessageModel

open class ImapFolderBuilder: NSObject, CWFolderBuilding {
    let connectInfo: EmailConnectInfo
    open let backgroundQueue: OperationQueue?

    public init(connectInfo: EmailConnectInfo, backgroundQueue: OperationQueue) {
        self.connectInfo = connectInfo
        self.backgroundQueue = backgroundQueue
    }

    open func folder(withName name: String) -> CWFolder {
        return PersistentImapFolder(name: name, connectInfo: connectInfo,
                                    backgroundQueue: backgroundQueue!) as CWFolder
    }

    deinit {
        print("ImapFolderBuilder.deinit")
    }
}

/**
 This operation is not intended to be put in a queue.
 It runs asynchronously, but mainly driven by the main runloop through the use of NSStream.
 Therefore it behaves as a concurrent operation, handling the state itself.
 */
open class FetchFoldersOperation: ConcurrentBaseOperation {
    let comp = "FetchFoldersOperation"
    var imapSync: ImapSync!
    let connectInfo: EmailConnectInfo
    let connectionManager: ConnectionManager
    var folderBuilder: ImapFolderBuilder!

    /**
     If this is true, the local folders will get checked, and only if important
     folders don't exist, the folders will get synced.
     */
    let onlyUpdateIfNecessary: Bool

    public init(connectInfo: EmailConnectInfo, connectionManager: ConnectionManager,
                onlyUpdateIfNecessary: Bool = false) {
        self.onlyUpdateIfNecessary = onlyUpdateIfNecessary
        self.connectInfo = connectInfo
        self.connectionManager = connectionManager

        super.init()

        folderBuilder = ImapFolderBuilder(connectInfo: connectInfo,
                                          backgroundQueue: backgroundQueue)
    }

    open override func main() {
        if self.isCancelled {
            return
        }

        // Serialize all folder storage to prevent duplicates
        backgroundQueue.maxConcurrentOperationCount = 1

        if onlyUpdateIfNecessary {
            // Check if the local folder list is fairly complete
            privateMOC.perform({
                var needSync = false
                let requiredTypes: [FolderType] = [.inbox, .sent, .drafts, .trash]
                for ty in requiredTypes {
                    if self.model.folderByType(ty, email: self.connectInfo.userName) == nil {
                        needSync = true
                        break
                    }
                }
                if needSync {
                    self.startSync()
                } else {
                    self.markAsFinished()
                }
            })
        } else {
            startSync()
        }
    }

    func startSync() {
        imapSync = connectionManager.emailSyncConnection(connectInfo)
        imapSync.delegate = self
        imapSync.folderBuilder = folderBuilder
        imapSync.start()
    }

    func readFolderNamesFromImapSync(_ sync: ImapSync) {
        if let _ = sync.folderNames {
            waitForFinished()
        }
    }
}

extension FetchFoldersOperation: ImapSyncDelegate {

    public func authenticationCompleted(_ sync: ImapSync, notification: Notification?) {
        if !self.isCancelled {
            readFolderNamesFromImapSync(sync)
        }
    }

    public func authenticationFailed(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorAuthenticationFailed(comp))
    }

    public func connectionLost(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorConnectionLost(comp))
    }

    public func connectionTerminated(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorConnectionTerminated(comp))
    }

    public func connectionTimedOut(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorConnectionTimeout(comp))
    }

    public func folderPrefetchCompleted(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorIllegalState(comp, stateName: "folderPrefetchCompleted"))
    }

    public func messageChanged(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorIllegalState(comp, stateName: "messageChanged"))
    }

    public func messagePrefetchCompleted(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorIllegalState(comp, stateName: "messagePrefetchCompleted"))
    }

    public func folderOpenCompleted(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorIllegalState(comp, stateName: "folderOpenCompleted"))
    }

    public func folderOpenFailed(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorIllegalState(comp, stateName: "folderOpenFailed"))
    }

    public func folderStatusCompleted(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorIllegalState(comp, stateName: "folderStatusCompleted"))
    }

    public func folderListCompleted(_ sync: ImapSync, notification: Notification?) {
        readFolderNamesFromImapSync(sync)
    }

    public func folderNameParsed(_ sync: ImapSync, notification: Notification?) {
        guard let userInfo = (notification as NSNotification?)?.userInfo else {
            return
        }
        guard let folderInfoDict = userInfo[PantomimeFolderInfo] as? NSDictionary else {
            return
        }
        guard let folderName = folderInfoDict[PantomimeFolderNameKey] as? String else {
            return
        }
        guard let folderSeparator = folderInfoDict[PantomimeFolderSeparatorKey]
            as? String else {
            return
        }

        let folderInfo = FolderInfo(name: folderName, separator: folderSeparator)
        let op = StoreFolderOperation(connectInfo: self.connectInfo, folderInfo: folderInfo)
        backgroundQueue.addOperation(op)
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
        addError(Constants.errorIllegalState(comp, stateName: "folderCreateCompleted"))
        markAsFinished()
    }

    public func folderCreateFailed(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorIllegalState(comp, stateName: "folderCreateFailed"))
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
