//
//  SyncFoldersFromServerOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 03/05/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import CoreData

import PantomimeFramework
import pEpIOSToolbox

/// It runs asynchronously, but mainly driven by the main runloop through the use of NSStream.
/// Therefore it behaves as a concurrent operation, handling the state itself.
class SyncFoldersFromServerOperation: ImapSyncOperation {
    private let saveContextWhenDone: Bool

    /// Collection of the names of all folders that exist on server.
    /// Used to sync local folders (might have been deleted/moved on server side)
    private var folderNamesExistingOnServer = [String]()

    init(parentName: String = #function,
         context: NSManagedObjectContext? = nil,
         errorContainer: ErrorContainerProtocol = ErrorPropagator(),
         imapConnection: ImapConnectionProtocol,
         saveContextWhenDone: Bool = true) {
        self.saveContextWhenDone = saveContextWhenDone

        super.init(parentName: parentName,
                   context: context,
                   errorContainer: errorContainer,
                   imapConnection: imapConnection)
        // Serialize all folder storage to prevent duplicates
        backgroundQueue.maxConcurrentOperationCount = 1
    }

    public override func main() {
        if !checkImapSync() || isCancelled {
            waitForBackgroundTasksAndFinish()
            return
        }
        startSync()
    }
}

// MARK: - Private

extension SyncFoldersFromServerOperation {

    private func startSync() {
        syncDelegate = SyncFoldersFromServerSyncDelegate(errorHandler: self)
        imapConnection.delegate = syncDelegate
        readFolderNamesFromImapSync(imapConnection)
    }

    private func readFolderNamesFromImapSync(_ imapConnection: ImapConnectionProtocol?) {
        imapConnection?.listFolders()
    }

    /// Deletes all local folders that do not exist on server any more (have been moved/deleted by
    /// another client).
    private func deleteLocalFoldersThatDoNotExistOnServerAnyMore() {
        backgroundQueue.addOperation { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            me.privateMOC.performAndWait {
                // Get all local folders that represent a remote mailbox
                guard let cdAccount = me.imapConnection.cdAccount(moc: me.privateMOC) else {
                    Log.shared.errorAndCrash("No account")
                    me.handle(error: BackgroundError.GeneralError.illegalState(info:
                        "Problem getting CdAccount"))
                    return
                }
                let localSyncedFolders = CdFolder.allRemoteFolders(inAccount: cdAccount,
                                                                   context: me.privateMOC)
                // Filter local folders that do not exist on server any more ...
                let foldersToDelete = localSyncedFolders.filter {
                    let subFoldersCount = $0.subFolders?.count ?? 0
                    return !me.folderNamesExistingOnServer.contains($0.nameOrCrash) &&
                        subFoldersCount == 0
                }
                guard !foldersToDelete.isEmpty else {
                    // Nothing to do.
                    return
                }
                // ... and delete them
                for deletee in foldersToDelete {
                    me.privateMOC.delete(deletee)
                }
                if me.saveContextWhenDone {
                    me.privateMOC.saveAndLogErrors()
                }
            }
            me.waitForBackgroundTasksAndFinish()
        }
    }

    private func storeFolder(imapFolderInfo: CdFolder.ImapFolderInfo) {
        backgroundQueue.addOperation { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            me.privateMOC.performAndWait {
                guard let cdAccount = me.imapConnection.cdAccount(moc: me.privateMOC) else {
                    Log.shared.error("No account. Valid case if the user deleted it.")
                    me.backgroundQueue.waitUntilAllOperationsAreFinished()
                    return
                }
                guard let server = cdAccount.server(type: .imap) else {
                    Log.shared.error("No IMAP server. Valid case if the user deleted the account.")
                    me.backgroundQueue.waitUntilAllOperationsAreFinished()
                    return
                }
                server.imapFolderSeparator = imapFolderInfo.separator
                CdFolder.updateOrCreateCdFolder(with: imapFolderInfo,
                                                inAccount: cdAccount,
                                                context: me.privateMOC)
            }
        }
    }
}

// MARK: - Callback Handlers

extension SyncFoldersFromServerOperation {
    fileprivate func handleFolderListCompleted(_ imapConnection: ImapConnectionProtocol?) {
        deleteLocalFoldersThatDoNotExistOnServerAnyMore()
    }

    fileprivate func handleFolderNameParsed(folderName: String,
                                            folderSeparator: String?,
                                            folderType: FolderType?,
                                            selectable: Bool = false) {
        folderNamesExistingOnServer.append(folderName)
        let folderInfo = CdFolder.ImapFolderInfo(name: folderName,
                                                 separator: folderSeparator,
                                                 folderType: folderType,
                                                 selectable: selectable)
        storeFolder(imapFolderInfo: folderInfo)
    }
}

// MARK: - SyncFoldersFromServerSyncDelegate

class SyncFoldersFromServerSyncDelegate: DefaultImapConnectionDelegate {

    public override func folderListCompleted(_ imapConnection: ImapConnectionProtocol, notification: Notification?) {
        guard let op = (errorHandler as? SyncFoldersFromServerOperation) else {
            Log.shared.errorAndCrash("No OP")
            return
        }
        op.handleFolderListCompleted(imapConnection)
    }

    public override func folderNameParsed(_ imapConnection: ImapConnectionProtocol, notification: Notification?) {
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

        guard let op = (errorHandler as? SyncFoldersFromServerOperation) else {
            Log.shared.errorAndCrash("No OP")
            return
        }
        op.handleFolderNameParsed(folderName: folderName,
                                  folderSeparator: folderSeparator,
                                  folderType:folderType,
                                  selectable: isSelectable)
    }
}
