//
//  SyncFoldersFromServerOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 03/05/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import CoreData

import MessageModel

protocol SyncFoldersFromServerOperationDelegate: class {
    /**
     Called if the folder was unknown before, and therefore newly created.
     */
    func didCreate(cdFolder: CdFolder)
}

/**
 This operation is not intended to be put in a queue.
 It runs asynchronously, but mainly driven by the main runloop through the use of NSStream.
 Therefore it behaves as a concurrent operation, handling the state itself.
 */
public class SyncFoldersFromServerOperation: ImapSyncOperation {
    var folderBuilder: ImapFolderBuilder!

    /**
     If this is true, the local folders will get checked, and only if important
     folders don't exist, the folders will get synced.
     */
    let onlyUpdateIfNecessary: Bool

    var syncDelegate: SyncFoldersFromServerSyncDelegate?

    weak var delegate: SyncFoldersFromServerOperationDelegate?

    /// Collection of the names of all folders that exist on server.
    /// Used to sync local folders (might have been deleted/moved on server side)
    var folderNamesExistingOnServer = [String]()

    // MARK: - LIFE CYCLE

    public init(parentName: String = #function,
                errorContainer: ServiceErrorProtocol = ErrorContainer(),
                imapSyncData: ImapSyncData, onlyUpdateIfNecessary: Bool = false) {
        self.onlyUpdateIfNecessary = onlyUpdateIfNecessary

        super.init(parentName: parentName, errorContainer: errorContainer,
                   imapSyncData: imapSyncData)

        folderBuilder = ImapFolderBuilder(
            accountID: imapSyncData.connectInfo.accountObjectID,
            backgroundQueue: backgroundQueue, messageFetchedBlock: nil)
    }

    // MARK: - PROCESS

    public override func main() {
        if !checkImapSync() {
            markAsFinished()
            return
        }

        // Serialize all folder storage to prevent duplicates
        backgroundQueue.maxConcurrentOperationCount = 1

        if onlyUpdateIfNecessary {
            // Check if the local folder list is fairly complete
            privateMOC.perform() { [weak self] in
                guard let me = self else {
                    Log.shared.errorAndCrash(component: #function,
                                             errorString: "Lost myselft")
                    return
                }
                guard let account = me.privateMOC.object(
                    with: me.imapSyncData.connectInfo.accountObjectID)
                    as? CdAccount else {
                        me.handleSeriousError(error:
                            BackgroundError.CoreDataError.couldNotFindAccount(info: me.comp))
                        return
                }

                var needSync = false

                for ty in FolderType.requiredTypes {
                    if CdFolder.by(folderType: ty, account: account) == nil {
                        needSync = true
                        break
                    }
                }
                if needSync {
                    me.startSync()
                } else {
                    me.markAsFinished()
                }
            }
        } else {
            startSync()
        }
    }

    func startSync() {
        syncDelegate = SyncFoldersFromServerSyncDelegate(errorHandler: self)
        imapSyncData.sync?.delegate = syncDelegate
        imapSyncData.sync?.folderBuilder = folderBuilder
        readFolderNamesFromImapSync(imapSyncData.sync)
    }

    func readFolderNamesFromImapSync(_ sync: ImapSync?) {
        let _ = sync?.folderNames
    }

    override func markAsFinished() {
        syncDelegate = nil
        super.markAsFinished()
    }

    /// Deletes all local folders that do not exist on server any more (have been moved/deleted by
    /// another client).
    private func deleteLocalFoldersThatDoNotExistOnServerAnyMore() {
        privateMOC.performAndWait { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash(component: #function, errorString: "Lost myself")
                return
            }
            // Get all local folders
            guard let cdAaccount =
                me.privateMOC.object(with: me.imapSyncData.connectInfo.accountObjectID)
                    as? CdAccount else {
                        handleSeriousError(error:
                            BackgroundError.CoreDataError.couldNotFindAccount(info: me.comp))
                        return
            }
            let account = cdAaccount.account()
            let localFolders = Folder.allFolders(inAccount: account)
            // Filter local folders that do not exist on server any more ...
            let foldersToDelete = localFolders.filter {
                !folderNamesExistingOnServer.contains($0.name)
            }
            // ... and delete them
            for deletee: Folder in foldersToDelete {
                deletee.delete()
            }
        }
    }

    private func handleSeriousError(error: Error) {
        self.addError(error)
        backgroundQueue.cancelAllOperations()
        waitForBackgroundTasksToFinish()
    }

    // MARK: - HANDLERS FOR SyncFoldersFromServerSyncDelegate

    fileprivate func handleFolderListCompleted(_ sync: ImapSync?) {
        backgroundQueue.waitUntilAllOperationsAreFinished()
        readFolderNamesFromImapSync(sync)
        deleteLocalFoldersThatDoNotExistOnServerAnyMore()
        markAsFinished()
    }

    fileprivate func handleFolderNameParsed(syncOp: SyncFoldersFromServerOperation,
                                            folderName: String,
                                            folderSeparator: String?,
                                            folderType: FolderType?,
                                            selectable: Bool = false) {
        folderNamesExistingOnServer.append(folderName)

        let folderInfo = StoreFolderOperation.FolderInfo(name: folderName,
                                                         separator: folderSeparator,
                                                         folderType: folderType,
                                                         selectable: selectable)
        let storeFolderOp = StoreFolderOperation(
            parentName: comp, connectInfo: syncOp.imapSyncData.connectInfo,
            folderInfo: folderInfo)
        storeFolderOp.delegate = self
        syncOp.backgroundQueue.addOperation(storeFolderOp)
    }
}

// MARK: - SyncFoldersFromServerSyncDelegate

class SyncFoldersFromServerSyncDelegate: DefaultImapSyncDelegate {

    public override func folderListCompleted(_ sync: ImapSync, notification: Notification?) {
        (errorHandler as? SyncFoldersFromServerOperation)?.handleFolderListCompleted(sync)
    }

    public override func folderNameParsed(_ sync: ImapSync, notification: Notification?) {
        guard let userInfo = (notification as NSNotification?)?.userInfo else {
            return
        }
        guard let folderInfoDict = userInfo[PantomimeFolderInfo] as? NSDictionary else {
            return
        }
        guard let folderName = folderInfoDict[PantomimeFolderNameKey] as? String else {
            return
        }
        guard let syncOp = errorHandler as? SyncFoldersFromServerOperation else {
            return
        }

        let folderSeparator = folderInfoDict[PantomimeFolderSeparatorKey] as? String

        // Check and handle if the folder is reported as Special-Use Mailbox by the server
        var folderType: FolderType? = nil
        if let specialUseMailboxType = folderInfoDict[PantomimeFolderSpecialUseKey] as? Int {
            folderType = FolderType.from(pantomimeSpecialUseMailboxType: specialUseMailboxType)
        }

        /*
         IMAP (and thus Pantomime) reports several folder attributes:
         PantomimeHoldsFolders = 1,
         PantomimeHoldsMessages = 2,
         PantomimeNoInferiors = 4,
         PantomimeNoSelect = 8,
         PantomimeMarked = 16,
         PantomimeUnmarked = 32

         We currently only take NoSelect into account. If we have to take others into account also
         change [Cd]Folder `isSelectable` field to `folderAttributes[RawVAlue]`.
         */
        var isSelectable = true
        if let rawFlags = folderInfoDict[PantomimeFolderFlagsKey] as? UInt32 {
            let folderFlags = PantomimeFolderAttribute(rawValue: rawFlags)
            isSelectable = folderFlags.isSelectable
        }

        (errorHandler as? SyncFoldersFromServerOperation)?.handleFolderNameParsed(syncOp: syncOp,
                                                                         folderName: folderName,
                                                                         folderSeparator: folderSeparator,
                                                                         folderType:folderType,
                                                                         selectable: isSelectable)
    }
}

// MARK: - StoreFolderOperationDelegate

extension SyncFoldersFromServerOperation: StoreFolderOperationDelegate {
    func didCreate(cdFolder: CdFolder) {
        delegate?.didCreate(cdFolder: cdFolder)
    }
}
