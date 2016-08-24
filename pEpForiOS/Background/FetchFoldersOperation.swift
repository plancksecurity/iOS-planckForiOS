//
//  FetchFoldersOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 03/05/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation
import CoreData

public class ImapFolderBuilder: NSObject, CWFolderBuilding {
    let connectInfo: ConnectInfo
    let grandOperator: IGrandOperator
    public let backgroundQueue: NSOperationQueue?

    public init(grandOperator: IGrandOperator, connectInfo: ConnectInfo,
                backgroundQueue: NSOperationQueue) {
        self.connectInfo = connectInfo
        self.grandOperator = grandOperator
        self.backgroundQueue = backgroundQueue
    }

    public func folderWithName(name: String) -> CWFolder {
        return PersistentImapFolder(name: name, grandOperator: grandOperator,
                                    connectInfo: connectInfo, backgroundQueue: backgroundQueue!)
            as CWFolder
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
public class FetchFoldersOperation: ConcurrentGrandOperatorOperation {
    let comp = "FetchFoldersOperation"
    var imapSync: ImapSync!
    let connectInfo: ConnectInfo
    var folderBuilder: ImapFolderBuilder!
    let coreDataUtil: ICoreDataUtil
    lazy var privateMOC: NSManagedObjectContext = self.coreDataUtil.privateContext()
    lazy var model: IModel = Model.init(context: self.privateMOC)

    /**
     If this is true, the local folders will get checked, and only if important
     folders don't exist, the folders will get synced.
     */
    let onlyUpdateIfNecessary: Bool

    public init(grandOperator: IGrandOperator, connectInfo: ConnectInfo,
                onlyUpdateIfNecessary: Bool) {
        self.onlyUpdateIfNecessary = onlyUpdateIfNecessary
        self.connectInfo = connectInfo
        coreDataUtil = grandOperator.coreDataUtil

        super.init(grandOperator: grandOperator)

        folderBuilder = ImapFolderBuilder.init(grandOperator: grandOperator,
                                               connectInfo: connectInfo,
                                               backgroundQueue: backgroundQueue)
    }

    convenience public init(grandOperator: IGrandOperator, connectInfo: ConnectInfo) {
        self.init(grandOperator: grandOperator,
                  connectInfo: connectInfo, onlyUpdateIfNecessary: false)
    }

    public override func main() {
        if self.cancelled {
            return
        }

        // Serialize all folder storage to prevent duplicates
        backgroundQueue.maxConcurrentOperationCount = 1

        if onlyUpdateIfNecessary {
            // Check if the local folder list is fairly complete
            privateMOC.performBlock({
                var needSync = false
                let requiredTypes: [FolderType] = [.Inbox, .Sent, .Drafts, .Trash]
                for ty in requiredTypes {
                    if self.model.folderByType(ty, email: self.connectInfo.email) == nil {
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
        imapSync = grandOperator.connectionManager.emailSyncConnection(connectInfo)
        imapSync.delegate = self
        imapSync.folderBuilder = folderBuilder
        imapSync.start()
    }

    func readFolderNamesFromImapSync(sync: ImapSync) {
        if let _ = sync.folderNames {
            waitForFinished()
        }
    }
}

extension FetchFoldersOperation: ImapSyncDelegate {

    public func authenticationCompleted(sync: ImapSync, notification: NSNotification?) {
        if !self.cancelled {
            readFolderNamesFromImapSync(sync)
        }
    }

    public func authenticationFailed(sync: ImapSync, notification: NSNotification?) {
        addError(Constants.errorAuthenticationFailed(comp))
    }

    public func connectionLost(sync: ImapSync, notification: NSNotification?) {
        addError(Constants.errorConnectionLost(comp))
    }

    public func connectionTerminated(sync: ImapSync, notification: NSNotification?) {
        addError(Constants.errorConnectionTerminated(comp))
    }

    public func connectionTimedOut(sync: ImapSync, notification: NSNotification?) {
        addError(Constants.errorConnectionTimeout(comp))
    }

    public func folderPrefetchCompleted(sync: ImapSync, notification: NSNotification?) {
        addError(Constants.errorIllegalState(comp, stateName: "folderPrefetchCompleted"))
    }

    public func messageChanged(sync: ImapSync, notification: NSNotification?) {
        addError(Constants.errorIllegalState(comp, stateName: "messageChanged"))
    }

    public func messagePrefetchCompleted(sync: ImapSync, notification: NSNotification?) {
        addError(Constants.errorIllegalState(comp, stateName: "messagePrefetchCompleted"))
    }

    public func folderOpenCompleted(sync: ImapSync, notification: NSNotification?) {
        addError(Constants.errorIllegalState(comp, stateName: "folderOpenCompleted"))
    }

    public func folderOpenFailed(sync: ImapSync, notification: NSNotification?) {
        addError(Constants.errorIllegalState(comp, stateName: "folderOpenFailed"))
    }

    public func folderStatusCompleted(sync: ImapSync, notification: NSNotification?) {
        addError(Constants.errorIllegalState(comp, stateName: "folderStatusCompleted"))
    }

    public func folderListCompleted(sync: ImapSync, notification: NSNotification?) {
        readFolderNamesFromImapSync(sync)
    }

    public func folderNameParsed(sync: ImapSync, notification: NSNotification?) {
        guard let userInfo = notification?.userInfo else {
            return
        }
        guard let folderInfoDict = userInfo[PantomimeFolderInfo] else {
            return
        }
        guard let folderName = folderInfoDict[PantomimeFolderNameKey] as? String else {
            return
        }
        guard let folderSeparator = folderInfoDict[PantomimeFolderSeparatorKey]
            as? String else {
            return
        }

        let folderInfo = FolderInfo.init(name: folderName, separator: folderSeparator)
        let op = StoreFolderOperation.init(
            coreDataUtil: coreDataUtil, folderInfo: folderInfo,
            email: self.connectInfo.email)
        backgroundQueue.addOperation(op)
    }

    public func actionFailed(sync: ImapSync, error: NSError) {
        addError(error)
    }
}