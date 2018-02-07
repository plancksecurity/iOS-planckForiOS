//
//  FetchFoldersOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 03/05/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import CoreData

import MessageModel

protocol FetchFoldersOperationOperationDelegate: class {
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
public class FetchFoldersOperation: ImapSyncOperation {
    var folderBuilder: ImapFolderBuilder!

    /**
     If this is true, the local folders will get checked, and only if important
     folders don't exist, the folders will get synced.
     */
    let onlyUpdateIfNecessary: Bool

    var syncDelegate: FetchFoldersSyncDelegate?

    weak var delegate: FetchFoldersOperationOperationDelegate?

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

    public override func main() {
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
                        self.addError(BackgroundError.CoreDataError.couldNotFindAccount(info: self.comp))
                        self.markAsFinished()
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
        syncDelegate = FetchFoldersSyncDelegate(errorHandler: self)
        imapSyncData.sync?.delegate = syncDelegate
        imapSyncData.sync?.folderBuilder = folderBuilder
        readFolderNamesFromImapSync(imapSyncData.sync)
    }

    func readFolderNamesFromImapSync(_ sync: ImapSync?) {
        if let _ = sync?.folderNames {
            waitForBackgroundTasksToFinish()
        }
    }

    override func markAsFinished() {
        syncDelegate = nil
        super.markAsFinished()
    }

    func folderNameParsed(syncOp: FetchFoldersOperation, folderName: String,
                          folderSeparator: String?,
                          folderType: FolderType?,
                          selectable: Bool = false) {
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

class FetchFoldersSyncDelegate: DefaultImapSyncDelegate {
    public override func folderListCompleted(_ sync: ImapSync, notification: Notification?) {
        (errorHandler as? FetchFoldersOperation)?.readFolderNamesFromImapSync(sync)
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
        guard let syncOp = errorHandler as? FetchFoldersOperation else {
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

        (errorHandler as? FetchFoldersOperation)?.folderNameParsed(syncOp: syncOp,
                                                                   folderName: folderName,
                                                                   folderSeparator: folderSeparator,
                                                                   folderType:folderType,
                                                                   selectable: isSelectable)
    }
}

extension FetchFoldersOperation: StoreFolderOperationDelegate {
    func didCreate(cdFolder: CdFolder) {
        delegate?.didCreate(cdFolder: cdFolder)
    }
}
