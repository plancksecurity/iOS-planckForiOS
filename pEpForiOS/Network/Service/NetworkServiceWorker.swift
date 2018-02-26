//
//  NetworkServiceWorker.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 13/02/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit
import CoreData

import MessageModel

public protocol NetworkServiceWorkerDelegate: class {
    /** Called after each account sync */
    func networkServicWorkerDidSync(worker: NetworkServiceWorker, accountInfo: AccountConnectInfo,
                 errorProtocol: ServiceErrorProtocol)

    /// Called finishing the last sync loop.
    /// No further sync loop will be triggered after this call.
    /// All operations finished before this call.
    /// - Parameters:
    ///   - worker: sender
    func networkServicWorkerDidFinishLastSyncLoop(worker: NetworkServiceWorker)

    /// Called after all operations have been canceled
    /// - Parameters:
    ///   - worker: sender
    func networkServicWorkerDidCancel(worker: NetworkServiceWorker)

    /// Used to report errors in operation line.
    /// - Parameters:
    ///   - worker: sender
    ///   - error: error reported by an operation in operation line
    func networkServiceWorker(_ worker: NetworkServiceWorker, errorOccured error: Error)
}

open class NetworkServiceWorker {
    public struct FolderInfo {
        public let name: String
        public let folderType: FolderType
        public let firstUID: UInt?
        public let lastUID: UInt?
        public let folderID: NSManagedObjectID?
    }

    class ObjectObserver: NSObject {
        let backgroundQueue: OperationQueue
        let operationCountKeyPath: String
        let myComp: String

        init(backgroundQueue: OperationQueue, operationCountKeyPath: String, myComp: String) {
            self.backgroundQueue = backgroundQueue
            self.operationCountKeyPath = operationCountKeyPath
            self.myComp = myComp
        }

        override open func observeValue(forKeyPath keyPath: String?, of object: Any?,
                                        change: [NSKeyValueChangeKey : Any]?,
                                        context: UnsafeMutableRawPointer?) {
            guard let newValue = change?[NSKeyValueChangeKey.newKey] else {
                super.observeValue(forKeyPath: keyPath, of: object, change: change,
                                   context: context)
                return
            }
            if keyPath == operationCountKeyPath {
                let opCount = (newValue as? NSNumber)?.intValue
                Log.verbose(component: #function, content: "operationCount \(String(describing: opCount))")
                dumpOperations()
            } else {
                super.observeValue(forKeyPath: keyPath, of: object, change: change,
                                   context: context)
            }
        }

        func dumpOperations() {
            for op in self.backgroundQueue.operations {
                Log.info(component: #function, content: "Still running: \(op)")
            }
        }
    }

    public weak var delegate: NetworkServiceWorkerDelegate?

    var serviceConfig: NetworkService.ServiceConfig

    var cancelled = false

    let workerQueue = DispatchQueue(
        label: "NetworkService", qos: .utility, target: nil)
    let backgroundQueue: OperationQueue = {
        let queue = OperationQueue()
        return queue
    }()

    let operationCountKeyPath = "operationCount"

    let context = Record.Context.background

    var imapConnectionDataCache = [EmailConnectInfo: ImapSyncData]()

    init(serviceConfig: NetworkService.ServiceConfig) {
        self.serviceConfig = serviceConfig
    }

    /**
     Start endlessly synchronizing in the background.
     */
    public func start() {
        Log.info(component: #function, content: "\(String(describing: self))")
        cancelled = false
        self.process()
    }

    /// Stops synchronizing after all local changes are synced to server.
    /// Calls delegate networkServicWorkerDidFinishLastSyncLoop when done.
    public func stop() {
        Log.info(component: #function, content: "\(String(describing: self))")
        syncLocalChangesWithServerAndStop()
    }

    /**
     Cancel all background operations, finish main loop.
     */
    public func cancel() {
        //476.SOI
        let myComp = #function

        self.cancelled = true
        self.backgroundQueue.cancelAllOperations()
        Log.info(component: myComp,
                 content: "\(String(describing: self)): all operations cancelled")

        workerQueue.async { // Looks suspiciouly like a potential retain cycle
            let observer = ObjectObserver(
                backgroundQueue: self.backgroundQueue,
                operationCountKeyPath: self.operationCountKeyPath, myComp: myComp)
            self.backgroundQueue.addObserver(observer, forKeyPath: self.operationCountKeyPath,
                                             options: [.initial, .new],
                                             context: nil)
            self.backgroundQueue.waitUntilAllOperationsAreFinished()
            self.backgroundQueue.removeObserver(observer, forKeyPath: self.operationCountKeyPath)
            self.delegate?.networkServicWorkerDidCancel(worker: self)
        }
    }

     /// Stops all queued operations, syncs all local changes with server and informs delegate
     /// when done.
    public func syncLocalChangesWithServerAndStop() {
        cancelled = true

        workerQueue.async { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash(component: #function, errorString: "Lost myself")
                return
            }

            me.backgroundQueue.cancelAllOperations()
            //IOS-958: debug
//            var counter = 0
//            while me.backgroundQueue.operations.count > 0 {
//                counter += 1
//                print("\(counter)OPS (#\(me.backgroundQueue.operations.count): \(me.backgroundQueue.operations)")
//                sleep(1)
//            }
            //END IOS-958
            me.backgroundQueue.waitUntilAllOperationsAreFinished()

            let connectInfos = ServiceUtil.gatherConnectInfos(context: me.context,
                                                              accounts: me.fetchAccounts())
            let operationLines =
                me.buildSyncLocalChangesOperationLines(accountConnectInfos: connectInfos)
            for operartionLine in operationLines {
                me.backgroundQueue.addOperations(operartionLine.operations,
                                                   waitUntilFinished: false)
            }
            me.backgroundQueue.waitUntilAllOperationsAreFinished()
            me.delegate?.networkServicWorkerDidFinishLastSyncLoop(worker: me)
        }
    }
    
    /**
     Start endlessly synchronizing in the background.
     */
    public func process(repeatProcess: Bool = true) {
        workerQueue.async {
            self.processAllInternal(repeatProcess: repeatProcess)
        }
    }

    /**
     Main entry point for the main loop.
     Implements RFC 4549 (https://tools.ietf.org/html/rfc4549).
     */
    func processAllInternal(repeatProcess: Bool = true) {
        if !cancelled {
            let connectInfos = ServiceUtil.gatherConnectInfos(context: context,
                                                              accounts: fetchAccounts())
            let operationLines = buildOperationLines(
                accountConnectInfos: connectInfos)
            processOperationLinesInternal(operationLines: operationLines,
                                          repeatProcess: repeatProcess)
        }
    }

    func fetchAccounts() -> [CdAccount] {
        let p = NSPredicate(format: "needsVerification = false")
        var result = [CdAccount]()
        context.performAndWait {
            result =  CdAccount.all(predicate: p, orderedBy: nil, in: context) as? [CdAccount] ?? []
        }
        return result
    }

    func buildSmtpOperations(accountInfo: AccountConnectInfo,
                             errorContainer: ServiceErrorProtocol,
                             opSmtpFinished: Operation,
                             lastOperation: Operation?) -> (BaseOperation?, [Operation]) {
        guard let smtpCI = accountInfo.smtpConnectInfo else {
            return (nil, [])
        }
        // 3.a Items not associated with any mailbox (e.g., SMTP send)
        let smtpSendData = SmtpSendData(connectInfo: smtpCI)
        let loginOp = LoginSmtpOperation(parentName: serviceConfig.parentName,
                                         smtpSendData: smtpSendData,
                                         errorContainer: errorContainer)
        loginOp.completionBlock = { [weak self] in
            loginOp.completionBlock = nil
            if let me = self {
                me.workerQueue.async {
                    Log.info(component: #function, content: "opSmtpLogin finished")
                }
            }
        }
        if let lastOp = lastOperation {
            loginOp.addDependency(lastOp)
        }
        opSmtpFinished.addDependency(loginOp)
        var operations = [Operation]()
        operations.append(loginOp)

        let sendOp = EncryptAndSendOperation(
            parentName: serviceConfig.parentName, smtpSendData: smtpSendData,
            errorContainer: errorContainer)
        sendOp.addDependency(loginOp)
        opSmtpFinished.addDependency(sendOp)
        operations.append(sendOp)
        
        return (sendOp, operations)
    }

    func buildAppendSendAndDraftOperations(
        imapSyncData: ImapSyncData, errorContainer: ServiceErrorProtocol,
        opImapFinished: Operation, previousOp: BaseOperation) -> (BaseOperation?, [Operation]) {

        let opAppend = AppendSendMailsOperation(
            parentName: serviceConfig.parentName, imapSyncData: imapSyncData,
            errorContainer: errorContainer)
        opAppend.addDependency(previousOp)
        opImapFinished.addDependency(opAppend)

        let opDrafts = AppendDraftMailsOperation(
            parentName: serviceConfig.parentName, imapSyncData: imapSyncData,
            errorContainer: errorContainer)
        opDrafts.addDependency(opAppend)
        opImapFinished.addDependency(opDrafts)

        return (opDrafts, [opAppend, opDrafts])
    }

    func buildTrashOperations(
        imapSyncData: ImapSyncData, errorContainer: ServiceErrorProtocol,
        opImapFinished: Operation, previousOp: BaseOperation) -> (BaseOperation?, [Operation]) {
        var lastOp = previousOp
        var trashOps = [AppendTrashMailsOperation]()
        let folders = AppendTrashMailsOperation.foldersWithTrashedMessages(context: context)
        for cdF in folders {
            let op = AppendTrashMailsOperation(
                parentName: serviceConfig.parentName, imapSyncData: imapSyncData,
                errorContainer: errorContainer, folder: cdF,
                syncTrashWithServer: FolderType.trash.shouldBeSyncedWithServer)
            op.addDependency(lastOp)
            opImapFinished.addDependency(op)
            lastOp = op
            trashOps.append(op)
        }
        return (lastOp, trashOps)
    }

    private func buildUidMoveMailsToTrashOperations(imapSyncData: ImapSyncData,
                                           errorContainer: ServiceErrorProtocol,
                                           opImapFinished: Operation,
                                           previousOp: BaseOperation) -> (BaseOperation?, [Operation]) {
        var lastOp = previousOp
        var createdOps = [UidMoveMailsToTrashOperation]()
        MessageModel.performAndWait {
            let folders = UidMoveMailsToTrashOperation.foldersContainingMarkedToUidMoveToTrash()
            for folder in folders {
                let op = UidMoveMailsToTrashOperation(imapSyncData: imapSyncData,
                                                      errorContainer: errorContainer,
                                                      folder: folder)
                op.addDependency(lastOp)
                opImapFinished.addDependency(op)
                lastOp = op
                createdOps.append(op)
            }
        }
        return (lastOp, createdOps)
    }

    /**
     Determine "interesting" folder names that should be synced, and for each:
     Determine current firstUID, lastUID, and store it (for later sync of existing messages).
     - Note: Interesting mailboxes are Inbox (always), and the most recently looked at
     folders.
     */
    public func determineInterestingFolders(accountInfo: AccountConnectInfo) -> [FolderInfo] {
        var folderInfos = [FolderInfo]()
        let context = Record.Context.background
        context.performAndWait {
            guard let account = context.object(with: accountInfo.accountID) as? CdAccount else {
                return
            }

            let earlierTimestamp = Date(
                timeIntervalSinceNow: -self.serviceConfig.timeIntervalForInterestingFolders)
            let pInteresting = NSPredicate(
                format: "account = %@ and lastLookedAt > %@", account,
                earlierTimestamp as CVarArg)
            let folders = CdFolder.all(predicate: pInteresting) as? [CdFolder] ?? []
            var haveInbox = false
            for f in folders {
                if let name = f.name {
                    if f.folderTypeRawValue == FolderType.inbox.rawValue {
                        haveInbox = true
                    }
                    folderInfos.append(FolderInfo(
                        name: name, folderType: f.folderType,
                        firstUID: f.firstUID(), lastUID: f.lastUID(), folderID: f.objectID))
                }
            }

            // Try to determine and add the inbox if it's not already there
            if !haveInbox {
                if let inboxFolder = CdFolder.by(folderType: .inbox, account: account) {
                    let name = inboxFolder.name ?? ImapSync.defaultImapInboxName
                    folderInfos.append(
                        FolderInfo(
                            name: name,
                            folderType: inboxFolder.folderType,
                            firstUID: inboxFolder.firstUID(), lastUID: inboxFolder.lastUID(),
                            folderID: inboxFolder.objectID))
                }
            }
        }
        if folderInfos.count == 0 {
            // If no interesting folders have been found, at least sync the inbox.
            folderInfos.append(FolderInfo(
                name: ImapSync.defaultImapInboxName, folderType: .inbox, firstUID: nil,
                lastUID: nil, folderID: nil))
        }
        return folderInfos
    }

    func syncExistingMessages(
        folderInfos: [FolderInfo], errorContainer: ServiceErrorProtocol,
        imapSyncData: ImapSyncData,
        lastImapOp: Operation, opImapFinished: Operation) -> (lastImapOp: Operation, [Operation]) {
        var theLastImapOp = lastImapOp
        var operations: [Operation] = []
        for fi in folderInfos {
            if let folderID = fi.folderID, let firstUID = fi.firstUID,
                let lastUID = fi.lastUID, firstUID != 0, lastUID != 0,
                firstUID <= lastUID {
                let syncMessagesOp = SyncMessagesOperation(
                    parentName: description, errorContainer: errorContainer,
                    imapSyncData: imapSyncData, folderName: fi.name,
                    firstUID: firstUID, lastUID: lastUID)
                syncMessagesOp.completionBlock = {
                    syncMessagesOp.completionBlock = nil
                    Log.info(component: #function, content: "syncMessagesOp finished")
                }
                syncMessagesOp.addDependency(theLastImapOp)
                operations.append(syncMessagesOp)
                opImapFinished.addDependency(syncMessagesOp)
                theLastImapOp = syncMessagesOp

                if let syncFlagsOp = SyncFlagsToServerOperation(parentName: description,
                                                                errorContainer: errorContainer,
                                                                imapSyncData: imapSyncData,
                                                                folderID: folderID) {
                    syncFlagsOp.addDependency(theLastImapOp)
                    operations.append(syncFlagsOp)
                    opImapFinished.addDependency(syncFlagsOp)
                    theLastImapOp = syncFlagsOp
                }
            }
        }
        return (theLastImapOp, operations)
    }

    func syncFlagsToServerOperations(
        folderInfos: [FolderInfo], errorContainer: ServiceErrorProtocol,
        imapSyncData: ImapSyncData,
        lastImapOp: Operation, opImapFinished: Operation) -> (lastImapOp: Operation, [Operation]) {
        var theLastImapOp = lastImapOp
        var operations: [Operation] = []
        for fi in folderInfos {
            if let folderID = fi.folderID, let firstUID = fi.firstUID,
                let lastUID = fi.lastUID, firstUID != 0, lastUID != 0,
                firstUID <= lastUID {
                if let syncFlagsOp = SyncFlagsToServerOperation(parentName: description,
                                                                errorContainer: errorContainer,
                                                                imapSyncData: imapSyncData,
                                                                folderID: folderID) {
                    syncFlagsOp.addDependency(theLastImapOp)
                    operations.append(syncFlagsOp)
                    opImapFinished.addDependency(syncFlagsOp)
                    theLastImapOp = syncFlagsOp
                }
            }
        }
        return (theLastImapOp, operations)
    }

    /// Builds a line of opertations to completely sync one e-mail account.
    /// Use this operation line when going into background.
    ///
    /// - Parameter accountInfo: Account info for account to sync
    /// - Returns:  Operation line contaning all operations required to sync one account
    func buildOperationLine(accountInfo: AccountConnectInfo) -> OperationLine {

        let errorContainer = ReportingErrorContainer(delegate: self)

        // Operation depending on all IMAP operations for this account
        let opImapFinished = BlockOperation { [weak self] in
            self?.workerQueue.async {
                Log.info(component: #function, content: "IMAP sync finished")
            }
        }

        // Operation depending on all SMTP operations for this account
        let opSmtpFinished = BlockOperation { [weak self] in
            self?.workerQueue.async {
                Log.info(component: #function, content: "SMTP sync finished")
            }
        }

        #if DEBUG
            var startTime = Date()
        #endif

        // Operation depending on all IMAP and SMTP operations
        let opAllFinished = BlockOperation { [weak self] in
            self?.workerQueue.async {
                #if DEBUG
                    Log.info(component: #function, content: "sync finished in \(-startTime.timeIntervalSinceNow) seconds")
                #else
                    Log.info(component: #function, content: "sync finished")
                #endif
            }
        }

        var operations = [Operation]()

        opAllFinished.addDependency(opImapFinished)
        opAllFinished.addDependency(opSmtpFinished)

        #if DEBUG
            let debugTimerOp = BlockOperation() {
                startTime = Date()
            }
            opAllFinished.addDependency(debugTimerOp)
            operations.append(debugTimerOp)
        #endif

        // If we need to report errors while fixing attachmnets, use
        // ReportingErrorContainer(delegate: self) here instead of ErrorContainer()
        let fixAttachmentsOp = FixAttachmentsOperation(parentName: description,
                                                       errorContainer: ErrorContainer())
        operations.append(fixAttachmentsOp)
        opAllFinished.addDependency(fixAttachmentsOp)

        // 3.a Items not associated with any mailbox (e.g., SMTP send)
        let (_, smtpOperations) = buildSmtpOperations(
            accountInfo: accountInfo, errorContainer: ReportingErrorContainer(delegate: self),
            opSmtpFinished: opSmtpFinished, lastOperation: fixAttachmentsOp)
        operations.append(contentsOf: smtpOperations)

        if let imapCI = accountInfo.imapConnectInfo {
            let imapSyncData = ServiceUtil.cachedImapSync(
                imapConnectionDataCache: imapConnectionDataCache, connectInfo: imapCI)

            // login IMAP
            let opImapLogin = LoginImapOperation(
                parentName: description, errorContainer: errorContainer,
                imapSyncData: imapSyncData)
            opImapLogin.addDependency(opSmtpFinished)
            opImapFinished.addDependency(opImapLogin)
            operations.append(opImapLogin)

            // 3.b Fetch current list of interesting mailboxes
            let opFetchFolders = FetchFoldersOperation(
                parentName: description, errorContainer: errorContainer,
                imapSyncData: imapSyncData)
            opFetchFolders.completionBlock = { [weak self] in
                opFetchFolders.completionBlock = nil
                if let me = self {
                    me.workerQueue.async {
                        Log.info(component: #function, content: "opFetchFolders finished")
                    }
                }
            }

            opFetchFolders.addDependency(opImapLogin)
            opImapFinished.addDependency(opFetchFolders)
            operations.append(opFetchFolders)

            let opRequiredFolders = CreateRequiredFoldersOperation(
                parentName: description, errorContainer: errorContainer,
                imapSyncData: imapSyncData)
            opRequiredFolders.addDependency(opFetchFolders)
            opImapFinished.addDependency(opRequiredFolders)
            operations.append(opRequiredFolders)

            // 3.c Client-to-server synchronization (IMAP)
            let (lastSendOp, sendOperations) = buildAppendSendAndDraftOperations(
                imapSyncData: imapSyncData, errorContainer: errorContainer,
                opImapFinished: opImapFinished, previousOp: opRequiredFolders)
            operations.append(contentsOf: sendOperations)

            let (lastTrashOp, trashOperations) = buildTrashOperations(
                imapSyncData: imapSyncData, errorContainer: errorContainer,
                opImapFinished: opImapFinished, previousOp: lastSendOp ?? opRequiredFolders)
            operations.append(contentsOf: trashOperations)

            // UidExpunge
            let (lastUidExpungeOp, uidExpungeOperations) =
                buildUidMoveMailsToTrashOperations(imapSyncData: imapSyncData,
                                          errorContainer: errorContainer,
                                          opImapFinished: opImapFinished,
                                          previousOp: lastTrashOp ?? lastSendOp ?? opRequiredFolders)
            operations.append(contentsOf: uidExpungeOperations)

            // 3.d Server-to-client synchronization (IMAP)

            let folderInfos = determineInterestingFolders(accountInfo: accountInfo)

            // sync new messages
            var lastImapOp: Operation = (lastUidExpungeOp ?? lastSendOp) ?? opRequiredFolders
            for fi in folderInfos {
                let fetchMessagesOp = FetchMessagesOperation(
                    parentName: description, errorContainer: errorContainer,
                    imapSyncData: imapSyncData, folderName: fi.name) {
                        [weak self] message in self?.messageFetched(cdMessage: message)
                }
                self.workerQueue.async {
                    Log.info(component: #function, content: "fetchMessagesOp finished")
                }
                operations.append(fetchMessagesOp)
                fetchMessagesOp.addDependency(lastImapOp)
                opImapFinished.addDependency(fetchMessagesOp)
                lastImapOp = fetchMessagesOp
            }

            // If we need to report errors while decrypting, use
            // ReportingErrorContainer(delegate: self) here instead of ErrorContainer()
            let opDecrypt = DecryptMessagesOperation(parentName: description,
                                                     errorContainer: ErrorContainer())

            opDecrypt.addDependency(lastImapOp)
            opImapFinished.addDependency(opDecrypt)
            operations.append(opDecrypt)
            opAllFinished.addDependency(opDecrypt)

            //comment to fullfil comment
            lastImapOp = opDecrypt // Don't sync messages after all messages got decrypted

            // sync existing messages
            let (lastOp, syncOperations) = syncExistingMessages(
                folderInfos: folderInfos, errorContainer: errorContainer,
                imapSyncData: imapSyncData, lastImapOp: lastImapOp, opImapFinished: opImapFinished)
            lastImapOp = lastOp
            operations.append(contentsOf: syncOperations)

            let logoutImapOp = BlockOperation() {
                imapSyncData.sync?.close()
            }
            logoutImapOp.addDependency(lastOp)
            opImapFinished.addDependency(logoutImapOp)
            lastImapOp = logoutImapOp
            operations.append(logoutImapOp)
        }

        operations.append(contentsOf: [opSmtpFinished, opImapFinished, opAllFinished])

        return OperationLine(accountInfo: accountInfo, operations: operations,
                             finalOperation: opAllFinished, errorContainer: errorContainer)
    }

    /// Builds a line of opertations that do just enough to make sure all user actions (sent,
    /// deleted, flagged) are synced with the server for one e-mail account.
    /// Use this operation line when going into background.
    ///
    /// - Parameter accountInfo: Account info for account to process user actions for.
    /// - Returns:  Operation line contaning all operations required to sync user actions
    ///             for one account.
    func buildSyncLocalChangesOperationLine(accountInfo: AccountConnectInfo) -> OperationLine {
        let errorContainer = ReportingErrorContainer(delegate: self)

        // Operation depending on all SMTP operations for this account
        let opSmtpFinished = BlockOperation { [weak self] in
            self?.workerQueue.async {
                Log.info(component: #function, content: "SMTP sync finished")
            }
        }
        // Operation depending on all IMAP operations for this account
        let opImapFinished = BlockOperation { [weak self] in
            self?.workerQueue.async {
                Log.info(component: #function, content: "IMAP sync finished")
            }
        }
        opImapFinished.addDependency(opSmtpFinished)
        #if DEBUG
            var startTime = Date()
        #endif

        // Operation depending on all IMAP and SMTP operations
        let opAllFinished = BlockOperation { [weak self] in
            self?.workerQueue.async {
                #if DEBUG
                    Log.info(component: #function,
                             content: "sync finished in \(-startTime.timeIntervalSinceNow) seconds")
                #else
                    Log.info(component: #function, content: "sync finished")
                #endif
            }
        }
        opAllFinished.addDependency(opSmtpFinished)
        opAllFinished.addDependency(opImapFinished)


        var operations = [Operation]()

        #if DEBUG
            let debugTimerOp = BlockOperation() {
                startTime = Date()
            }
            opAllFinished.addDependency(debugTimerOp)
            operations.append(debugTimerOp)
        #endif

        // SMTP
        // send
        let (_, smtpOperations) =
            buildSmtpOperations(accountInfo: accountInfo,
                                errorContainer: ReportingErrorContainer(delegate: self),
                                opSmtpFinished: opSmtpFinished,
                                lastOperation: nil)
        operations.append(contentsOf: smtpOperations)

        // IMAP
        if let imapCI = accountInfo.imapConnectInfo {
            let imapSyncData = ServiceUtil.cachedImapSync(
                imapConnectionDataCache: imapConnectionDataCache, connectInfo: imapCI)

            // login
            let opImapLogin = LoginImapOperation(
                parentName: description, errorContainer: errorContainer,
                imapSyncData: imapSyncData)
            opImapFinished.addDependency(opImapLogin)
            operations.append(opImapLogin)

            // append sent
            let (lastSendOp, sendOperations) = buildAppendSendAndDraftOperations(
                imapSyncData: imapSyncData, errorContainer: errorContainer,
                opImapFinished: opImapFinished, previousOp: opImapLogin)
            operations.append(contentsOf: sendOperations)

            // append trash
            let (lastTrashOp, trashOperations) =
                buildTrashOperations(imapSyncData: imapSyncData,
                                     errorContainer: errorContainer,
                                     opImapFinished: opImapFinished,
                                     previousOp: lastSendOp ?? opImapLogin)
            operations.append(contentsOf: trashOperations)
            let (lastUidExpungeOp, uidExpungeOperations) =
                buildUidMoveMailsToTrashOperations(imapSyncData: imapSyncData,
                                          errorContainer: errorContainer,
                                          opImapFinished: opImapFinished,
                                          previousOp: lastTrashOp ?? lastSendOp ?? opImapLogin)
            operations.append(contentsOf: uidExpungeOperations)

            // sync flags
            let folderInfos = determineInterestingFolders(accountInfo: accountInfo)
            let (lastSyncFlagsOp, syncFlagsOps) =
                syncFlagsToServerOperations(folderInfos: folderInfos,
                                            errorContainer: errorContainer,
                                            imapSyncData: imapSyncData,
                                            lastImapOp: lastUidExpungeOp
                                                ?? lastTrashOp
                                                ?? lastSendOp
                                                ?? opImapLogin,
                                            opImapFinished: opImapFinished)
            operations.append(contentsOf: syncFlagsOps)

            let logoutImapOp = BlockOperation() {
                imapSyncData.sync?.close()
            }
            logoutImapOp.addDependency(lastSyncFlagsOp)
            opImapFinished.addDependency(logoutImapOp)
            operations.append(logoutImapOp)
        }

        operations.append(contentsOf: [opSmtpFinished, opImapFinished, opAllFinished])

        return OperationLine(accountInfo: accountInfo, operations: operations,
                             finalOperation: opAllFinished, errorContainer: errorContainer)
    }

    func messageFetched(cdMessage: CdMessage) {
        if cdMessage.imap?.serverFlags?.flagDeleted ?? true == false {
            serviceConfig.sendLayerDelegate?.didFetch(cdMessage: cdMessage)
        }
    }

    func buildOperationLines(accountConnectInfos: [AccountConnectInfo]) -> [OperationLine] {
        return accountConnectInfos.map {
            return buildOperationLine(accountInfo: $0)
        }
    }

    func buildSyncLocalChangesOperationLines(accountConnectInfos: [AccountConnectInfo]) -> [OperationLine] {
        return accountConnectInfos.map {
            return buildSyncLocalChangesOperationLine(accountInfo: $0)
        }
    }

    func scheduleOperationLine(
        operationLine: OperationLine, completionBlock: (() -> Void)? = nil) {
        if cancelled {
            return
        }
        let bgID = serviceConfig.backgrounder?.beginBackgroundTask()
        operationLine.finalOperation.completionBlock = { [weak self, weak operationLine] in
            operationLine?.finalOperation.completionBlock = nil
            self?.serviceConfig.backgrounder?.endBackgroundTask(bgID)
            completionBlock?()
        }
        for op in operationLine.operations {
            if cancelled {
                //476.SOI
                backgroundQueue.cancelAllOperations()
                return
            }
            backgroundQueue.addOperation(op)
        }
    }

    func processOperationLines(operationLines: [OperationLine]) {
        if cancelled {
            return
        }
        workerQueue.async { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash(component: #function, errorString: "Lost myself")
                return
            }
            if me.cancelled {
                return
            }
            me.processOperationLinesInternal(operationLines: operationLines)
        }
    }

    func processOperationLinesInternal(operationLines: [OperationLine], repeatProcess: Bool = true) {
        let theComp = "\(#function) processOperationLinesInternal"
        if !self.cancelled {
            var myLines = operationLines
            Log.verbose(component: theComp,
                        content: "\(operationLines.count) left, repeat? \(repeatProcess)")
            if myLines.first != nil {
                let ol = myLines.removeFirst()
                scheduleOperationLine(operationLine: ol, completionBlock: {
                    [weak self, weak ol] in
                    Log.verbose(component: theComp,
                                content: "finished \(operationLines.count) left, repeat? \(repeatProcess)")
                    guard let me = self, let theOl = ol else {
                        return
                    }
                    Log.info(component: theComp,
                             content: "didSync")
                    me.delegate?.networkServicWorkerDidSync(worker: me,
                                                            accountInfo: theOl.accountInfo,
                                                            errorProtocol: theOl.errorContainer)
                    // Process the rest
                    me.processOperationLines(operationLines: myLines)
                })
            } else {
                workerQueue.asyncAfter(deadline: DispatchTime.now() +
                    self.serviceConfig.sleepTimeInSeconds) { [weak self] in
                        guard let strongSelf = self else {
                            return
                        }
                        if repeatProcess && !strongSelf.cancelled{
                            strongSelf.processAllInternal()
                        }
                }
            }
        } else {
            Log.verbose(component: theComp, content: "canceled with \(operationLines.count)")
        }
    }
}

// MARK: - ReportingErrorContainerDelegate

extension NetworkServiceWorker: ReportingErrorContainerDelegate {
    public func reportingErrorContainer(_ errorContainer: ReportingErrorContainer, didReceive error: Error) {
        delegate?.networkServiceWorker(self, errorOccured: error)
    }
}

// MARK: - CustomStringConvertible

extension NetworkServiceWorker: CustomStringConvertible {
    public var description: String {
        let parentDescription = serviceConfig.parentName
        let ref = unsafeBitCast(self, to: UnsafeRawPointer.self)
        return "NetworkServiceWorker \(ref) (\(parentDescription))"
    }
}
