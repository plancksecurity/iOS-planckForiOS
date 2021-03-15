//
//  ImapReplicationService.swift
//  MessageModel
//
//  Created by Andreas Buff on 15.10.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import CoreData
import pEpIOSToolbox

extension ImapReplicationService {

    private enum PollingMode {
        case normal
        case fastPolling
    }
}

/// Replicates the state of an IMAP server (for one account).
class ImapReplicationService: OperationBasedService {
    private var pollingMode: PollingMode
    /// Amount of time to "sleep" between polling cycles
    private var sleepTimeInSeconds = MiscUtil.isUnitTest() ? 1.0 : 10.0
    private var cdAccount: CdAccount? = nil
    private var imapConnectionCache = ImapConnectionCache()
    private var idleOperation: ImapIdleOperation?

    /// - Parameters:
    ///   - backgroundTaskManager: see Service.init for docs
    ///   - cdAccountObjectID: Object ID for IMAP account to replicate.
    ///                         - note: the account MUST contain a CdServer that is of type IMAP.
    ///   - errorPropagator: see Service.init for docs
    init(backgroundTaskManager: BackgroundTaskManagerProtocol? = nil,
         cdAccountObjectID: NSManagedObjectID,
         errorPropagator: ErrorContainerProtocol? = nil) {

        self.pollingMode = .normal
        super.init(useSerialQueue: true,
                   backgroundTaskManager: backgroundTaskManager,
                   errorPropagator: errorPropagator)
        privateMoc.performAndWait {
            cdAccount = privateMoc.object(with: cdAccountObjectID) as? CdAccount
        }

        // Custom finisBlock to make sure all local changes (made by the user) are synced with the server.
        finishBlock = { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            me.state = .finshing
            let toDos = me.internalOperations(syncOnlyUserChanges: true)
            me.backgroundQueue.addOperations(toDos, waitUntilFinished: false)
            me.waitThenStop()
        }
    }

    // MARK: - Overrides

    override func operations() -> [Operation] {
        return internalOperations()
    }

	override func finish() {
        idleOperation?.stopIdling()
        idleOperation = nil
        super.finish()
    }

    override func stop() {
        idleOperation?.stopIdling()
        idleOperation = nil
        super.stop()
    }
}

// MARK: - Private

extension ImapReplicationService {

    private func internalOperations(syncOnlyUserChanges: Bool = false) -> [Operation] {
        var createes = [Operation]()
        privateMoc.performAndWait { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }

            guard
                let cdAccount = me.cdAccount,
                let imapConnectInfo = cdAccount.imapConnectInfo else {
                    Log.shared.errorAndCrash("%@ - No connect info.", "\(type(of: self))")
                    let reportErrorAndWaitOp = me.errorHandlerOp(error: BackgroundError.ImapError.invalidAccount)
                    createes.append(reportErrorAndWaitOp)
                    return
            }

            let imapConnection = me.imapConnectionCache.imapConnection(for: imapConnectInfo)

            // login IMAP
            let opImapLogin = LoginImapOperation(errorContainer: me.errorPropagator,
                                                 imapConnection: imapConnection)
            createes.append(opImapLogin)

            if me.pollingMode != .fastPolling && !syncOnlyUserChanges {
                // Fetch current list of interesting mailboxes
                let opSyncFolders = SyncFoldersFromServerOperation(errorContainer: me.errorPropagator,
                                                                   imapConnection: imapConnection)
                createes.append(opSyncFolders)
            }
            if me.pollingMode != .fastPolling && !syncOnlyUserChanges  {
                let opRequiredFolders = CreateRequiredFoldersOperation(errorContainer: me.errorPropagator,
                                                                       imapConnection: imapConnection)
                createes.append(opRequiredFolders)
            }

            // Client-to-server synchronization (IMAP)
            let appendOp = AppendMailsOperation(errorContainer: me.errorPropagator,
                                                imapConnection: imapConnection)
            createes.append(appendOp)

            if me.pollingMode != .fastPolling {
                let moveToFolderOp = ImapMoveOperation(errorContainer: me.errorPropagator,
                                                       imapConnection: imapConnection)
                createes.append(moveToFolderOp)
            }

            let folderInfos = me.determineInterestingFolders(for: cdAccount)

            // Server-to-client synchronization (IMAP)
            // fetch new messages
            if !syncOnlyUserChanges {
                let fetchMessagesOp = FetchMessagesOperation(errorContainer: me.errorPropagator,
                                                             imapConnection: imapConnection,
                                                             folderInfos: folderInfos)
                createes.append(fetchMessagesOp)
            }

            if me.pollingMode != .fastPolling && !syncOnlyUserChanges {
                // Send EXPUNGEs, if necessary
                let expungeOP = ImapExpungeOperation(errorContainer: me.errorPropagator,
                                                     imapConnection: imapConnection)
                createes.append(expungeOP)
            }
            if me.pollingMode != .fastPolling && !syncOnlyUserChanges {
                // sync existing messages
                let syncExistingOP = SyncMessagesOperation(errorContainer: me.errorPropagator,
                                                           imapConnection: imapConnection,
                                                           folderInfos: folderInfos)
                createes.append(syncExistingOP)
            }
            if me.pollingMode != .fastPolling {
                let syncFlagsToServer = SyncFlagsToServerOperation(errorContainer: me.errorPropagator,
                                                                   imapConnection: imapConnection,
                                                                   folderInfos: folderInfos)
                createes.append(syncFlagsToServer)
            }
            // Commented out as IDLE is broken. See IOS-1632
            //            var willIdle = false
            //            if me.pollingMode != .fastPolling && imapConnection.supportsIdle {
            //                let idleOP = ImapIdleOperation(errorContainer: me.errorPropagator,
            //                                               imapConnection: imapConnection)
            //                createes.append(idleOP)
            //                me.idleOperation = idleOP
            //                willIdle = true
            //            }
            //            if !willIdle {
            // The server does not support idle mode. So we must poll frequently.
            if !syncOnlyUserChanges {
                createes.append(me.pollingPausingOp(errorContainer: me.errorPropagator))
                createes.append(me.errorHandlerOp())
            }
        }
        return createes
    }

    private func pollingPausingOp(errorContainer: ErrorContainerProtocol) -> Operation {
        let pauseOp = SelfReferencingOperation { [weak self] operation in
            guard let me = self else {
                // It's a valid case. The service might have been nil-ed intentionally.
                Log.shared.info("Lost myself")
                return
            }
            guard
                !errorContainer.hasErrors,
                let operation = operation,
                !operation.isCancelled else {
                    // We are gone, we got canceled, or an error occured ...
                    // ... Do nothing
                    return
            }
            if me.pollingMode == .fastPolling {
                Log.shared.info("%@ - fastPolling", "\(type(of: me))")
                // We need a little break here. Certain servers deny to answer when polling without break.
                let fastPollingPauseTime = 1.0
                sleep(UInt32(fastPollingPauseTime))
            } else {
                Log.shared.info("%@ - now sleeping for %f seconds",
                                "\(type(of: me))", me.sleepTimeInSeconds)
                let startDate = Date()
                while Date().timeIntervalSince(startDate) < me.sleepTimeInSeconds {
                    if operation.isCancelled || me.lastCommand == .finish { // lastcommand should be private. We need to use it as we can curently not cancel the running OPs in finishBlock, due to IMAPSyncOPs concept makes graceful cancelling impossible. rm ` || me.lastCommand == .finish ` after IMAPSyncOPs are cancelable and make `lastCommand` privagte again.
                        break
                    }
                    sleep(1)
                }
                Log.shared.info("%@ - woke up", "\(type(of: me))")
            }
        }
        return pauseOp
    }

    //BUFF:  Must be moved to use in OPs?
    //BUFF: when IDLE is in, make all important folders interesting?

    /// Folders (other than inbox) that the user looked at in the last
    /// `timeIntervalForInterestingFolders` are considered sync-worthy.
    static let timeIntervalForInterestingFolders: TimeInterval = 60 * 10
    /// Determine "interesting" folder names that should be synced, and for each: Determine current
    /// firstUID, lastUID, and store it (for later sync of existing messages). - Note: Interesting
    /// mailboxes are Inbox (always), and the most recently looked at folders.
    private func determineInterestingFolders(for cdAccount: CdAccount) -> [FolderInfo] {
        var folderInfos = [FolderInfo]()

        // Set of folder type that are in the list to be updated
        var interestingFolderTypes = Set<FolderType>()

        // For fast polling, we want to fetch messages only from Inbox, so Inbox must be the only
        // interesting folder
        if pollingMode != .fastPolling {
            let earlierTimestamp = Date(
                timeIntervalSinceNow: -ImapReplicationService.timeIntervalForInterestingFolders)
            let pInteresting = CdFolder.PredicateFactory
                .folders(for: cdAccount,
                         lastLookedAfter: earlierTimestamp)
            let folderPredicate = NSCompoundPredicate(
                orPredicateWithSubpredicates: [pInteresting,
                                               CdFolder.PredicateFactory.pEpSyncFolder(cdAccount: cdAccount)])
            let folders = CdFolder.all(predicate: folderPredicate,
                                       in: privateMoc) as? [CdFolder] ?? []

            for f in folders {
                if let name = f.name {
                    interestingFolderTypes.insert(f.folderType)
                    folderInfos.append(FolderInfo(name: name,
                                                  folderType: f.folderType,
                                                  firstUID: f.firstUID(context: privateMoc),
                                                  lastUID: f.lastUID(context: privateMoc),
                                                  folderID: f.objectID))
                }
            }
        }

        // Try to determine and add inbox folder if not already there. It considered as always
        // interesting.
        if !interestingFolderTypes.contains(.inbox) {
            if let inboxFolder = CdFolder.by(folderType: .inbox,
                                             account: cdAccount,
                                             context: privateMoc) {
                let name = inboxFolder.name ?? ImapConnection.defaultInboxName
                folderInfos.append(FolderInfo(name: name,
                                              folderType: inboxFolder.folderType,
                                              firstUID: inboxFolder.firstUID(context: privateMoc),
                                              lastUID: inboxFolder.lastUID(context: privateMoc),
                                              folderID: inboxFolder.objectID))
            }
        }

        // If we have a special sync folder, this is considered interesting as well,
        // like the inbox.
        if !interestingFolderTypes.contains(.pEpSync) {
            if let syncFolder = CdFolder.pEpSyncFolder(in: privateMoc, cdAccount: cdAccount),
                let foldername = syncFolder.name {
                folderInfos.append(FolderInfo(name: foldername,
                                              folderType: syncFolder.folderType,
                                              firstUID: syncFolder.firstUID(context: privateMoc),
                                              lastUID: syncFolder.lastUID(context: privateMoc),
                                              folderID: syncFolder.objectID))
            }
        }

        if folderInfos.count == 0 {
            // If no interesting folders have been found, at least sync the inbox.
            folderInfos.append(FolderInfo(name: ImapConnection.defaultInboxName,
                                          folderType: .inbox,
                                          firstUID: nil,
                                          lastUID: nil,
                                          folderID: nil))
        }
        return folderInfos
    }
}

// MARK: - ReplicationServiceProtocol

extension ImapReplicationService: ReplicationServiceProtocol {

    func enableFastPolling() {
        pollingMode = .fastPolling
    }

    func disableFastPolling() {
        pollingMode = .normal
    }
}
