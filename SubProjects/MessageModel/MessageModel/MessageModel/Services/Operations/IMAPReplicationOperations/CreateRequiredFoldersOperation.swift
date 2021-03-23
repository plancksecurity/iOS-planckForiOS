//
//  CreateRequiredFoldersOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 01/03/17.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit
import CoreData

#if EXT_SHARE
import pEpIOSToolboxForExtensions
#else
import pEpIOSToolbox
#endif

///Checks for needed folders, like "Drafts", and when they don't exist, create them
/// both locally and remote.
class CreateRequiredFoldersOperation: ImapSyncOperation {
    private struct FolderToCreate {
        var folderName: String
        let folderSeparator: String?
        let folderType: FolderType
        let cdAccount: CdAccount
    }
    private struct CreationAttempt {
        var count = 0
        var folderToCreate: FolderToCreate?

        mutating func reset() {
            count = 0
            folderToCreate = nil
        }
    }
    private var currentAttempt = CreationAttempt()
    private var foldersToCreate = [FolderToCreate]()
    private var folderSeparator: String?
    /// Whether or not the client or this operation is responsible for saving the context
    private var saveContextWhenDone: Bool

    init(parentName: String = #function,
         context: NSManagedObjectContext? = nil,
         errorContainer: ErrorContainerProtocol = ErrorPropagator(),
         imapConnection: ImapConnectionProtocol,
         saveContextWhenDone: Bool = true) {
        self.saveContextWhenDone = saveContextWhenDone
        super.init(context: context,
                   errorContainer: errorContainer,
                   imapConnection: imapConnection)
    }

    override func main() {
        if !checkImapConnection() {
            waitForBackgroundTasksAndFinish()
            return
        }
        process()
    }

    /// Update the local folder separator, if not already set, and if the
    /// given folder has one.
    ///
    /// The reason for this is that we get the folder separator delivered for each folder,
    /// and we need it for parsing folder hierarchies correctly.
    ///
    /// - Parameter folder: The folder to provide the folder separator
    private func updateFolderSeparator(folder: CdFolder) {
        if folderSeparator == nil {
            folderSeparator = folder.folderSeparatorAsString()
        }
    }

    private func process() {
        backgroundQueue.addOperation { [weak self] in
            guard let me = self else {
                Log.shared.lostMySelf()
                return
            }
            me.privateMOC.performAndWait {
                guard
                    let account = me.imapConnection.cdAccount(moc: me.privateMOC) else {
                        me.handle(error: BackgroundError.CoreDataError.couldNotFindAccount(info: me.comp))
                        return
                }

                me.assureLocalFoldersExist(for: account)

                for ft in FolderType.requiredTypes {
                    if let cdF = CdFolder.by(folderType: ft,
                                             account: account,
                                             context: me.privateMOC) {
                        me.updateFolderSeparator(folder: cdF)
                    } else {
                        // No folder found for the required type, so try to match it by name only
                        if let theFoundFolder = me.localFolderByAssumedNameForType(folderType: ft,
                                                                                   account: account,
                                                                                   context: me.privateMOC) {
                            theFoundFolder.folderType = ft
                            me.updateFolderSeparator(folder: theFoundFolder)
                        } else {
                            let folderName = ft.folderName()
                            me.foldersToCreate.append(FolderToCreate(folderName: folderName,
                                                                     folderSeparator: me.folderSeparator,
                                                                     folderType: ft,
                                                                     cdAccount: account))
                        }
                    }
                }

                if me.folderSeparator == nil {
                    me.folderSeparator = CdFolder.folderSeparatorAsString(cdAccount: account)
                }

                if me.foldersToCreate.count > 0 {
                    me.syncDelegate = CreateRequiredFoldersSyncDelegate(errorHandler: me)
                    me.imapConnection.delegate = me.syncDelegate
                    me.createNextFolder()
                } else {
                    me.savecontext()
                    me.waitForBackgroundTasksAndFinish()
                }
            }
        }
    }

    /// Probes the DB for a folder that _could_ match the given folder type by name,
    /// not directly by type.
    ///
    /// Looks for folders by name, deriving that name based on the given folder type.
    /// E.g., it would find a folder "INBOX.Trash" based on the `.trash` type, if
    /// that folder has no type set.
    ///
    /// - Parameters:
    ///   - folderType: The desired folder type
    ///   - account: CdAccount
    ///   - context: The context to access the DB
    private func localFolderByAssumedNameForType(folderType: FolderType,
                                                 account: CdAccount,
                                                 context: NSManagedObjectContext) -> CdFolder? {
        // Get common names for the given folder type
        let folderNames = folderType.folderNames()

        // Create folder name variants, e.g. by prepending "INBOX." to the names
        let folderNameVariations = folderNames.map() {
            return [$0, "\(ImapConnection.defaultInboxName).\($0)"]
        }

        // Loop over all possibilities and try to look folders up by name
        for fnArray in folderNameVariations {
            for fn in fnArray {
                if let cdF = CdFolder.by(name: fn, account: account, context: context) {
                    // make sure the folder is available for the folder type role we want
                    if cdF.folderType == .normal && cdF.selectable {
                        return cdF
                    }
                }
            }
        }

        return nil
    }

    private func savecontext() {
        if saveContextWhenDone {
            privateMOC.saveAndLogErrors()
        }
    }

    fileprivate func createNextFolder() {
        backgroundQueue.addOperation { [weak self] in
            guard let me = self else {
                Log.shared.lostMySelf()
                return
            }
            me.privateMOC.performAndWait {
                if let lastFolder = me.currentAttempt.folderToCreate {
                    me.createLocal(folderToCreate: lastFolder)
                }
                guard !me.isCancelled, let _ = me.foldersToCreate.first else {
                    // We have been cancelled or there is nothing left todo.
                    me.savecontext()
                    me.waitForBackgroundTasksAndFinish()
                    return
                }
            }
            guard let folderToCreate = me.foldersToCreate.first else {
                me.waitForBackgroundTasksAndFinish()
                return
            }
            me.currentAttempt.reset()
            me.currentAttempt.folderToCreate = folderToCreate
            me.startFolderCreation(folderToCreate: folderToCreate)
            me.foldersToCreate.removeFirst()
        }
    }

    private func startFolderCreation(folderToCreate: FolderToCreate) {
        imapConnection.createFolderNamed(folderToCreate.folderName)
    }

    private func createLocal(folderToCreate: FolderToCreate) {
        let _ = CdFolder.updateOrCreate(folderName: folderToCreate.folderName,
                                        folderSeparator: folderToCreate.folderSeparator,
                                        folderType: folderToCreate.folderType,
                                        account: folderToCreate.cdAccount)
    }

    fileprivate func createFolderAgain(potentialError: Error) {
        backgroundQueue.addOperation { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            if me.currentAttempt.count == 0, var folderToCreate = me.currentAttempt.folderToCreate,
                let fs = me.folderSeparator {
                folderToCreate.folderName =
                "\(ImapConnection.defaultInboxName)\(fs)\(folderToCreate.folderName)"
                me.currentAttempt.folderToCreate = folderToCreate
                me.currentAttempt.count += 1
                me.startFolderCreation(folderToCreate: folderToCreate)
            } else {
                me.currentAttempt.reset()
                me.handle(error: potentialError)
            }
        }
    }

    private func assureLocalFoldersExist(for account: CdAccount) {
        if let _ = CdFolder.by(folderType: .outbox, account: account, context: privateMOC) {
            // Nothing to do. Outbox is currently the only existing local folder type
            return
        }
        let name = FolderType.outbox.folderName()

        let newFolder = CdFolder(context: privateMOC)
        newFolder.name = name
        newFolder.account = account
        newFolder.folderType = .outbox
        newFolder.selectable = true
        savecontext()
    }
}

// MARK: - Callback Handler

extension CreateRequiredFoldersOperation {
    fileprivate func handleFolderCreateCompleted() {
        createNextFolder()
    }

    fileprivate func handleFolderCreateFailed() {
        createFolderAgain(potentialError: ImapSyncOperationError.illegalState(#function))
    }
}

// MARK: - DefaultImapSyncDelegate

class CreateRequiredFoldersSyncDelegate: DefaultImapConnectionDelegate {
    override func folderCreateCompleted(_ imapConnection: ImapConnectionProtocol, notification: Notification?) {
        guard let op = errorHandler as? CreateRequiredFoldersOperation else {
            Log.shared.errorAndCrash("Sorry, wrong number.")
            return
        }
        op.handleFolderCreateCompleted()
    }

    override func folderCreateFailed(_ imapConnection: ImapConnectionProtocol, notification: Notification?) {
        guard let op = errorHandler as? CreateRequiredFoldersOperation else {
            Log.shared.errorAndCrash("Sorry, wrong number.")
            return
        }
        op.handleFolderCreateFailed()
    }
}
