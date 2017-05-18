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
    
    var serviceConfig: NetworkService.ServiceConfig

    var cancelled = false

    let workerQueue = DispatchQueue(
        label: "NetworkService", qos: .utility, target: nil)
    let backgroundQueue = OperationQueue()

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
        Log.info(component: #function, content: "\(String(describing: self)) starting")
        self.process()
    }

    /**
     Cancel all background operations, finish main loop.
     */
    public func cancel(networkService: NetworkService) {
        let myComp = #function

        self.cancelled = true
        self.backgroundQueue.cancelAllOperations()
        Log.info(component: myComp, content: "\(String(describing: self)): all operations cancelled")

        workerQueue.async {
            let observer = ObjectObserver(
                backgroundQueue: self.backgroundQueue,
                operationCountKeyPath: self.operationCountKeyPath, myComp: myComp)
            self.backgroundQueue.addObserver(observer, forKeyPath: self.operationCountKeyPath,
                                             options: [.initial, .new],
                                             context: nil)

            self.backgroundQueue.waitUntilAllOperationsAreFinished()
            self.backgroundQueue.removeObserver(observer, forKeyPath: self.operationCountKeyPath)
            self.serviceConfig.networkServiceDelegate?.didCancel(service: networkService)
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
        let p = NSPredicate(value: true)
        let sortDescriptors = [NSSortDescriptor(key: "needsVerification", ascending: false)]
        return CdAccount.all(
            predicate: p, orderedBy: sortDescriptors, in: context) as? [CdAccount] ?? []
    }

    func checkVerified(accountInfo: AccountConnectInfo,
                       operations: [BaseOperation]) {
        if accountInfo.needsVerification {
            context.performAndWait {
                guard let account = self.context.object(with: accountInfo.accountID) as? CdAccount else {
                    return
                }
                var accountVerified = true
                let allCreds = account.credentials?.array as? [CdServerCredentials] ?? []
                for theCreds in allCreds {
                    if theCreds.needsVerification == true {
                        accountVerified = false
                        break
                    }
                }
                if accountVerified {
                    account.needsVerification = false
                    Record.saveAndWait(context: self.context)
                    self.serviceConfig.sendLayerDelegate?.didVerify(cdAccount: account, error: nil)
                    self.serviceConfig.mySelfer?.startMySelf()
                } else {
                    var error: NSError?
                    for op in operations {
                        if let err = op.error {
                            error = err
                            break
                        }
                    }
                    if let err = error {
                        self.serviceConfig.sendLayerDelegate?.didVerify(cdAccount: account, error: err)
                    } else {
                        self.serviceConfig.sendLayerDelegate?.didVerify(
                            cdAccount: account,
                            error: Constants.errorIllegalState(
                                #function,
                                stateName: NSLocalizedString(
                                    "Failed Verification",
                                    comment:
                                    "error messages when verification failed without error")))
                    }
                }
            }
        }
    }

    func buildSmtpOperations(
        accountInfo: AccountConnectInfo, errorContainer: ServiceErrorProtocol,
        opSmtpFinished: Operation, lastOperation: Operation?) -> (BaseOperation?, [Operation]) {
        if let smtpCI = accountInfo.smtpConnectInfo {
            // 3.a Items not associated with any mailbox (e.g., SMTP send)
            let smtpSendData = SmtpSendData(connectInfo: smtpCI)
            let loginOp = LoginSmtpOperation(
                smtpSendData: smtpSendData, errorContainer: errorContainer)
            loginOp.completionBlock = { [weak self] in
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

            let sendOp = EncryptAndSendOperation(smtpSendData: smtpSendData,
                                                 errorContainer: errorContainer)
            opSmtpFinished.addDependency(sendOp)
            sendOp.addDependency(loginOp)
            operations.append(sendOp)

            return (sendOp, operations)
        } else {
            return (nil, [])
        }
    }

    func buildSendOperations(
        imapSyncData: ImapSyncData, errorContainer: ServiceErrorProtocol,
        opImapFinished: Operation, previousOp: BaseOperation) -> (BaseOperation?, [Operation]) {

        let opAppend = AppendMailsOperation(imapSyncData: imapSyncData)
        opAppend.addDependency(previousOp)
        opImapFinished.addDependency(opAppend)

        let opDrafts = AppendDraftMailsOperation(imapSyncData: imapSyncData)
        opDrafts.addDependency(opAppend)
        opImapFinished.addDependency(opDrafts)

        return (opDrafts, [opAppend, opDrafts])
    }

    func buildTrashOperations(
        imapSyncData: ImapSyncData, errorContainer: ServiceErrorProtocol,
        opImapFinished: Operation, previousOp: BaseOperation) -> (BaseOperation?, [Operation]) {
        var lastOp = previousOp
        var trashOps = [TrashMailsOperation]()
        let folders = TrashMailsOperation.foldersWithTrashedMessages(context: context)
        for cdF in folders {
            let op = TrashMailsOperation(imapSyncData: imapSyncData, folder: cdF)
            op.addDependency(lastOp)
            opImapFinished.addDependency(op)
            lastOp = op
            trashOps.append(op)
        }
        return (lastOp, trashOps)
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
                    if f.folderType == FolderType.inbox.rawValue {
                        haveInbox = true
                    }
                    folderInfos.append(FolderInfo(
                        name: name, folderType: FolderType(rawValue: f.folderType) ?? .normal,
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
                            folderType: FolderType(rawValue: inboxFolder.folderType) ?? .inbox,
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
                    parentName: debugDescription, errorContainer: errorContainer,
                    imapSyncData: imapSyncData, folderID: folderID, folderName: fi.name,
                    firstUID: firstUID, lastUID: lastUID)
                syncMessagesOp.completionBlock = { _ in
                    Log.info(component: #function, content: "syncMessagesOp finished")
                }
                syncMessagesOp.addDependency(theLastImapOp)
                operations.append(syncMessagesOp)
                opImapFinished.addDependency(syncMessagesOp)
                theLastImapOp = syncMessagesOp

                if let syncFlagsOp = SyncFlagsToServerOperation(
                    parentName: debugDescription, errorContainer: errorContainer,
                    imapSyncData: imapSyncData, folderID: folderID) {
                    syncFlagsOp.addDependency(theLastImapOp)
                    operations.append(syncFlagsOp)
                    opImapFinished.addDependency(syncFlagsOp)
                    theLastImapOp = syncFlagsOp
                }
            }
        }
        return (theLastImapOp, operations)
    }

    func buildOperationLine(accountInfo: AccountConnectInfo) -> OperationLine {

        let errorContainer = ErrorContainer()

        // Operation depending on all IMAP operations for this account
        let opImapFinished = BlockOperation { [weak self] in
            self?.workerQueue.async {
                Log.warn(component: #function, content: "IMAP sync finished")
            }
        }

        // Operation depending on all SMTP operations for this account
        let opSmtpFinished = BlockOperation { [weak self] in
            self?.workerQueue.async {
                Log.warn(component: #function, content: "SMTP sync finished")
            }
        }

        // Operation depending on all IMAP and SMTP operations
        let opAllFinished = BlockOperation { [weak self] in
            self?.workerQueue.async {
                Log.info(component: #function, content: "sync finished")
            }
        }
        opAllFinished.addDependency(opImapFinished)
        opAllFinished.addDependency(opSmtpFinished)

        var operations: [Operation] = []

        let fixAttachmentsOp = FixAttachmentsOperation(
            parentName: debugDescription, errorContainer: ErrorContainer())
        operations.append(fixAttachmentsOp)
        opAllFinished.addDependency(fixAttachmentsOp)

        // 3.a Items not associated with any mailbox (e.g., SMTP send)
        let (lastSmtpOp, smtpOperations) = buildSmtpOperations(
            accountInfo: accountInfo, errorContainer: ErrorContainer(),
            opSmtpFinished: opSmtpFinished, lastOperation: fixAttachmentsOp)
        operations.append(contentsOf: smtpOperations)

        if let imapCI = accountInfo.imapConnectInfo {
            let imapSyncData = ServiceUtil.cachedImapSync(
                imapConnectionDataCache: imapConnectionDataCache, connectInfo: imapCI)

            // login IMAP
            let opImapLogin = LoginImapOperation(
                parentName: debugDescription, errorContainer: errorContainer,
                imapSyncData: imapSyncData)
            opImapLogin.completionBlock = { [weak self, weak opImapLogin] in
                self?.workerQueue.async {
                    if let me = self, let theOpImapLogin = opImapLogin {
                        var ops: [BaseOperation] = [theOpImapLogin]
                        if let op = lastSmtpOp {
                            ops.append(op)
                        }
                        me.checkVerified(accountInfo: accountInfo, operations: ops)
                        Log.info(component: #function, content: "opImapLogin finished")
                    }
                }
            }
            opImapLogin.addDependency(opSmtpFinished)
            opImapFinished.addDependency(opImapLogin)
            operations.append(opImapLogin)

            // 3.b Fetch current list of interesting mailboxes
            let opFetchFolders = FetchFoldersOperation(
                parentName: debugDescription, errorContainer: errorContainer,
                imapSyncData: imapSyncData)
            opFetchFolders.completionBlock = { [weak self] in
                if let me = self {
                    me.workerQueue.async {
                        Log.info(component: #function, content: "opFetchFolders finished")
                    }
                }
            }

            operations.append(opFetchFolders)
            opFetchFolders.addDependency(opImapLogin)
            opImapFinished.addDependency(opFetchFolders)

            let opSpecialFolder = CreateSpecialFoldersOperation(
                parentName: debugDescription, errorContainer: errorContainer,
                imapSyncData: imapSyncData)
            operations.append(opSpecialFolder)
            opSpecialFolder.addDependency(opFetchFolders)
            opImapFinished.addDependency(opSpecialFolder)

            // 3.c Client-to-server synchronization (IMAP)
            let (lastSendOp, sendOperations) = buildSendOperations(
                imapSyncData: imapSyncData, errorContainer: errorContainer,
                opImapFinished: opImapFinished, previousOp: opSpecialFolder)
            operations.append(contentsOf: sendOperations)

            let (lastTrashOp, trashOperations) = buildTrashOperations(
                imapSyncData: imapSyncData, errorContainer: errorContainer,
                opImapFinished: opImapFinished, previousOp: lastSendOp ?? opFetchFolders)
            operations.append(contentsOf: trashOperations)

            // 3.d Server-to-client synchronization (IMAP)

            let folderInfos = determineInterestingFolders(accountInfo: accountInfo)

            // sync new messages
            var lastImapOp: Operation = lastTrashOp ?? opFetchFolders
            for fi in folderInfos {
                let fetchMessagesOp = FetchMessagesOperation(
                    parentName: debugDescription, errorContainer: errorContainer,
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

            let opDecrypt = DecryptMessagesOperation(
                parentName: debugDescription, errorContainer: ErrorContainer())

            opDecrypt.addDependency(lastImapOp)
            opImapFinished.addDependency(opDecrypt)
            operations.append(opDecrypt)

            // sync existing messages
            let (lastOp, syncOperations) = syncExistingMessages(
                folderInfos: folderInfos, errorContainer: errorContainer,
                imapSyncData: imapSyncData, lastImapOp: lastImapOp, opImapFinished: opImapFinished)
            lastImapOp = lastOp
            operations.append(contentsOf: syncOperations)
        }

        // ...

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

    func scheduleOperationLineInternal(
        operationLine: OperationLine, completionBlock: (() -> Void)?) {
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
                backgroundQueue.cancelAllOperations()
                return
            }
            backgroundQueue.addOperation(op)
        }
    }

    func processOperationLines(operationLines: [OperationLine]) {
        if !cancelled {
            workerQueue.async {
                self.processOperationLinesInternal(operationLines: operationLines)
            }
        }
    }

    func processOperationLinesInternal(operationLines: [OperationLine],
                                       repeatProcess: Bool = true) {
        let theComp = "\(#function) processOperationLinesInternal"
        if !self.cancelled {
            var myLines = operationLines
            Log.verbose(component: theComp,
                        content: "\(operationLines.count) left, repeat? \(repeatProcess)")
            if myLines.first != nil {
                let ol = myLines.removeFirst()
                scheduleOperationLineInternal(operationLine: ol, completionBlock: {
                    [weak self, weak ol] in
                    Log.verbose(component: theComp,
                                content: "finished \(operationLines.count) left, repeat? \(repeatProcess)")
                    if let me = self, let theOl = ol,
                        let service = me.serviceConfig.networkService {
                        Log.info(component: theComp,
                                 content: "didSync \(String(describing: me.serviceConfig.networkServiceDelegate))")
                        me.serviceConfig.networkServiceDelegate?.didSync(
                            service: service, accountInfo: theOl.accountInfo,
                            errorProtocol: theOl.errorContainer)
                        // Process the rest
                        me.processOperationLines(operationLines: myLines)
                    }
                })
            } else {
                if repeatProcess && !cancelled {
                    workerQueue.asyncAfter(deadline: DispatchTime.now() +
                        self.serviceConfig.sleepTimeInSeconds) {
                        self.processAllInternal()
                    }
                }
            }
        } else {
            Log.verbose(component: theComp, content: "canceled with \(operationLines.count)")
        }
    }
}

extension NetworkServiceWorker: CustomDebugStringConvertible {
    public var debugDescription: String {
        let parentDescription = serviceConfig.parentName ?? "UnknownParent"
        let ref = unsafeBitCast(self, to: UnsafeRawPointer.self)
        return "NetworkServiceWorker \(ref) (\(parentDescription))"
    }
}

extension NetworkServiceWorker: CustomStringConvertible {
    public var description: String {
        return debugDescription
    }
}
