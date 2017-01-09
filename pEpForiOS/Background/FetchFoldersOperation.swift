//
//  FetchFoldersOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 03/05/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import CoreData

import MessageModel

/**
 Calling this block indicates that a message has been fetched and stored.
 */
public typealias MessageFetchedBlock = (_ message: CdMessage) -> ()

open class ImapFolderBuilder: NSObject, CWFolderBuilding {
    let accountID: NSManagedObjectID
    open let backgroundQueue: OperationQueue?
    let name: String?
    let messageFetchedBlock: MessageFetchedBlock?

    public init(accountID: NSManagedObjectID, backgroundQueue: OperationQueue,
                name: String? = nil, messageFetchedBlock: MessageFetchedBlock? = nil) {
        self.accountID = accountID
        self.backgroundQueue = backgroundQueue
        self.name = name
        self.messageFetchedBlock = messageFetchedBlock
    }

    open func folder(withName name: String) -> CWFolder {
        return PersistentImapFolder(
            name: name, accountID: accountID, backgroundQueue: backgroundQueue!,
            logName: name, messageFetchedBlock: messageFetchedBlock) as CWFolder
    }

    deinit {
        Log.info(component: "ImapFolderBuilder: \(name)", content: "ImapFolderBuilder.deinit")
    }
}

/**
 This operation is not intended to be put in a queue.
 It runs asynchronously, but mainly driven by the main runloop through the use of NSStream.
 Therefore it behaves as a concurrent operation, handling the state itself.
 */
open class FetchFoldersOperation: ImapSyncOperation {
    var folderBuilder: ImapFolderBuilder!

    /**
     If this is true, the local folders will get checked, and only if important
     folders don't exist, the folders will get synced.
     */
    let onlyUpdateIfNecessary: Bool

    public init(parentName: String? = nil, errorContainer: ErrorProtocol = ErrorContainer(),
                imapSyncData: ImapSyncData, onlyUpdateIfNecessary: Bool = false,
                messageFetchedBlock: MessageFetchedBlock? = nil) {
        self.onlyUpdateIfNecessary = onlyUpdateIfNecessary

        super.init(parentName: parentName, errorContainer: errorContainer,
                   imapSyncData: imapSyncData)

        folderBuilder = ImapFolderBuilder(
            accountID: imapSyncData.connectInfo.accountObjectID,
            backgroundQueue: backgroundQueue, messageFetchedBlock: messageFetchedBlock)
    }

    deinit {}

    open override func main() {
        if !shouldRun() {
            return
        }

        if !checkImapSync() {
            return
        }

        // Serialize all folder storage to prevent duplicates
        backgroundQueue.maxConcurrentOperationCount = 1

        if onlyUpdateIfNecessary {
            // Check if the local folder list is fairly complete
            privateMOC.perform({
                guard let account = self.privateMOC.object(
                    with: self.imapSyncData.connectInfo.accountObjectID)
                    as? CdAccount else {
                        self.addError(Constants.errorCannotFindAccount(component: self.comp))
                        self.markAsFinished()
                        return
                }

                var needSync = false
                let requiredTypes: [FolderType] = [.inbox, .sent, .drafts, .trash]
                for ty in requiredTypes {
                    if CdFolder.by(folderType: ty, account: account) == nil {
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
        imapSync.delegate = self
        imapSync.folderBuilder = folderBuilder
        readFolderNamesFromImapSync(imapSync)
    }

    func readFolderNamesFromImapSync(_ sync: ImapSync) {
        if let _ = sync.folderNames {
            waitForFinished()
        }
    }
}

extension FetchFoldersOperation: ImapSyncDelegate {

    public func authenticationCompleted(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorIllegalState(comp, stateName: "authenticationCompleted"))
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

    public func folderSyncCompleted(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorIllegalState(comp, stateName: "folderSyncCompleted"))
        markAsFinished()
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

        let folderSeparator = folderInfoDict[PantomimeFolderSeparatorKey] as? String
        let folderInfo = FolderInfo(name: folderName, separator: folderSeparator)
        let op = StoreFolderOperation(connectInfo: self.imapSyncData.connectInfo,
                                      folderInfo: folderInfo)
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
