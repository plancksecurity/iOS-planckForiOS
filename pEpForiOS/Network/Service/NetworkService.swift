//
//  NetworkService.swift
//  pEpForiOS
//
//  Created by hernani on 10/10/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation
import CoreData

import MessageModel

public protocol INetworkService {
}

public protocol NetworkServiceDelegate: class {
    /** Called after each account sync */
    func didSync(service: NetworkService, accountInfo: AccountConnectInfo,
                 errorProtocol: ServiceErrorProtocol)

    /** Called after all operations have been canceled */
    func didCancel(service: NetworkService)
}

/**
 * Provides all the IMAP and SMTP syncing. Will constantly run in the background.
 */
public class NetworkService: INetworkService {
    public struct FolderInfo {
        public let name: String
        public let folderType: FolderType
        public let firstUID: UInt?
        public let lastUID: UInt?
        public let folderID: NSManagedObjectID?
    }

    let operationCountKeyPath = "operationCount"

    /**
     Folders (other than inbox) that the user looked at
     in the last `timeIntervalForInterestingFolders`
     are considered sync-worthy.
     */
    public var timeIntervalForInterestingFolders: TimeInterval = 60 * 60 * 24

    let comp = "NetworkService"

    public var sendLayerDelegate: SendLayerDelegate?

    /**
     Amount of time to "sleep" between complete syncs of all accounts.
     */
    public var sleepTimeInSeconds: Double

    let workerQueue = DispatchQueue(
        label: "NetworkService", qos: .utility, target: nil)
    let backgroundQueue = OperationQueue()

    var cancelled = false
    var currentOperations = Set<Operation>()

    public weak var networkServiceDelegate: NetworkServiceDelegate?

    let parentName: String?

    let backgrounder: BackgroundTaskProtocol?
    let mySelfer: KickOffMySelfProtocol?

    let context = Record.Context.background

    public init(sleepTimeInSeconds: Double = 10.0, parentName: String? = nil,
                backgrounder: BackgroundTaskProtocol? = nil,
                mySelfer: KickOffMySelfProtocol? = nil) {
        self.sleepTimeInSeconds = sleepTimeInSeconds
        self.parentName = parentName
        self.backgrounder = backgrounder
        self.mySelfer = mySelfer ?? DefaultMySelfer(backgrounder: backgrounder)
    }

    /**
     Start endlessly synchronizing in the background.
     */
    public func start() {
        self.process()
    }

    /**
     Start endlessly synchronizing in the background.
     */
    public func process(repeatProcess: Bool = true, needsVerificationOnly: Bool = false) {
        workerQueue.async {
            self.processAllInternal(repeatProcess: repeatProcess,
                                    needsVerificationOnly: needsVerificationOnly)
        }
    }

    /**
     Cancel all background operations, finish main loop.
     */
    public func cancel() {
        workerQueue.async {
            let myComp = "cancelOp"
            Log.info(component: myComp, content: "cancel()")

            let observer = ObjectObserver(
                backgroundQueue: self.backgroundQueue,
                operationCountKeyPath: self.operationCountKeyPath, myComp: myComp)
            self.backgroundQueue.addObserver(observer, forKeyPath: self.operationCountKeyPath,
                                             options: [.initial, .new],
                                             context: nil)

            self.cancelled = true
            self.backgroundQueue.cancelAllOperations()
            Log.info(component: myComp, content: "all operations cancelled")

            self.backgroundQueue.waitUntilAllOperationsAreFinished()
            self.networkServiceDelegate?.didCancel(service: self)
        }
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
                Log.verbose(component: myComp, content: "operationCount \(opCount)")
                dumpOperations()
            } else {
                super.observeValue(forKeyPath: keyPath, of: object, change: change,
                                   context: context)
            }
        }

        func dumpOperations() {
            for op in self.backgroundQueue.operations {
                Log.info(component: myComp, content: "Still running: \(op)")
            }
        }
    }

    func fetchAccounts(needsVerificationOnly: Bool = false) -> [CdAccount] {
        let p = NSPredicate(format: "needsVerification = %@",
                            NSNumber(booleanLiteral: needsVerificationOnly))
        return CdAccount.all(predicate: p, in: context) as? [CdAccount] ?? []
    }

    func gatherConnectInfos(needsVerificationOnly: Bool = false) -> [AccountConnectInfo] {
        var connectInfos = [AccountConnectInfo]()
        context.performAndWait {
            let accounts = self.fetchAccounts(needsVerificationOnly: needsVerificationOnly)
            for acc in accounts {
                let smtpCI = acc.smtpConnectInfo
                let imapCI = acc.imapConnectInfo
                if (smtpCI != nil || imapCI != nil) {
                    connectInfos.append(AccountConnectInfo(
                        accountID: acc.objectID, imapConnectInfo: imapCI, smtpConnectInfo: smtpCI))
                }
            }
        }
        return connectInfos
    }

    func checkVerified(accountInfo: AccountConnectInfo,
                       operations: [BaseOperation], needsVerificationOnly: Bool) {
        if needsVerificationOnly {
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
                    self.sendLayerDelegate?.didVerify(cdAccount: account, error: nil)
                    self.mySelfer?.startMySelf()
                } else {
                    var error: NSError?
                    for op in operations {
                        if let err = op.error {
                            error = err
                            break
                        }
                    }
                    if let err = error {
                        self.sendLayerDelegate?.didVerify(cdAccount: account, error: err)
                    } else {
                        self.sendLayerDelegate?.didVerify(
                            cdAccount: account,
                            error: Constants.errorIllegalState(
                                self.comp,
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
        opSmtpFinished: Operation) -> (BaseOperation?, [Operation]) {
        if let smtpCI = accountInfo.smtpConnectInfo {
            // 3.a Items not associated with any mailbox (e.g., SMTP send)
            let smtpSendData = SmtpSendData(connectInfo: smtpCI)
            let loginOp = LoginSmtpOperation(
                smtpSendData: smtpSendData, errorContainer: errorContainer)
            loginOp.completionBlock = { [weak self] in
                if let me = self {
                    me.workerQueue.async {
                        Log.info(component: me.comp, content: "opSmtpLogin finished")
                    }
                }
            }
            opSmtpFinished.addDependency(loginOp)
            var operations = [Operation]()
            operations.append(loginOp)

            let sendOp = EncryptAndSendOperation(smtpSendData: smtpSendData)
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
                timeIntervalSinceNow: -self.timeIntervalForInterestingFolders)
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
                    parentName: parentName, errorContainer: errorContainer,
                    imapSyncData: imapSyncData, folderID: folderID, folderName: fi.name,
                    firstUID: firstUID, lastUID: lastUID)
                syncMessagesOp.completionBlock = { [weak self] in
                    if let me = self {
                        Log.info(component: me.comp, content: "syncMessagesOp finished")
                    }
                }
                syncMessagesOp.addDependency(theLastImapOp)
                operations.append(syncMessagesOp)
                opImapFinished.addDependency(syncMessagesOp)
                theLastImapOp = syncMessagesOp

                if let syncFlagsOp = SyncFlagsToServerOperation(
                    parentName: parentName, errorContainer: errorContainer,
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

    func buildOperationLine(
        accountInfo: AccountConnectInfo, needsVerificationOnly: Bool) -> OperationLine {

        let errorContainer = ErrorContainer()

        // Operation depending on all IMAP operations for this account
        let opImapFinished = BlockOperation { [weak self] in
            self?.workerQueue.async {
                if let me = self {
                    Log.warn(component: me.comp, content: "IMAP sync finished")
                }
            }
        }

        // Operation depending on all SMTP operations for this account
        let opSmtpFinished = BlockOperation { [weak self] in
                self?.workerQueue.async {
                    if let me = self {
                        Log.warn(component: me.comp, content: "SMTP sync finished")
                    }
                }
        }

        // Operation depending on all IMAP and SMTP operations
        let opAllFinished = BlockOperation { [weak self] in
            self?.workerQueue.async {
                if let me = self {
                    Log.info(component: me.comp, content: "sync finished")
                }
            }
        }
        opAllFinished.addDependency(opImapFinished)
        opAllFinished.addDependency(opSmtpFinished)

        var operations: [Operation] = []

        // 3.a Items not associated with any mailbox (e.g., SMTP send)
        let (lastSmtpOp, smtpOperations) = buildSmtpOperations(
            accountInfo: accountInfo, errorContainer: errorContainer,
            opSmtpFinished: opSmtpFinished)
        operations.append(contentsOf: smtpOperations)

        if let imapCI = accountInfo.imapConnectInfo {
            // TODO: Reuse connections
            let imapSyncData = ImapSyncData(connectInfo: imapCI)

            // login IMAP
            // TODO: Check if needed
            let opImapLogin = LoginImapOperation(
                imapSyncData: imapSyncData, name: parentName, errorContainer: errorContainer)
            opImapLogin.completionBlock = { [weak self, weak opImapLogin] in
                self?.workerQueue.async {
                    if let me = self, let theOpImapLogin = opImapLogin {
                        var ops: [BaseOperation] = [theOpImapLogin]
                        if let op = lastSmtpOp {
                            ops.append(op)
                        }
                        me.checkVerified(
                            accountInfo: accountInfo, operations: ops,
                            needsVerificationOnly: needsVerificationOnly)
                        Log.info(component: me.comp, content: "opImapLogin finished")
                    }
                }
            }
            opImapLogin.addDependency(opSmtpFinished)
            opImapFinished.addDependency(opImapLogin)
            operations.append(opImapLogin)

            // 3.b Fetch current list of interesting mailboxes
            let opFetchFolders = FetchFoldersOperation(
                parentName: parentName, errorContainer: errorContainer, imapSyncData: imapSyncData)
            opFetchFolders.completionBlock = { [weak self] in
                if let me = self {
                    me.workerQueue.async {
                        Log.info(component: me.comp, content: "opFetchFolders finished")
                    }
                }
            }
            operations.append(opFetchFolders)
            opFetchFolders.addDependency(opImapLogin)
            opImapFinished.addDependency(opFetchFolders)

            // 3.c Client-to-server synchronization (IMAP)
            let (lastSendOp, sendOperations) = buildSendOperations(
                imapSyncData: imapSyncData, errorContainer: errorContainer,
                opImapFinished: opImapFinished, previousOp: opFetchFolders)
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
                    parentName: parentName, errorContainer: errorContainer,
                    imapSyncData: imapSyncData, folderName: fi.name) {
                        [weak self] message in self?.messageFetched(cdMessage: message)
                }
                self.workerQueue.async {
                    Log.info(component: self.comp, content: "fetchMessagesOp finished")
                }
                operations.append(fetchMessagesOp)
                fetchMessagesOp.addDependency(lastImapOp)
                opImapFinished.addDependency(fetchMessagesOp)
                lastImapOp = fetchMessagesOp
            }

            let opDecrypt = DecryptMessagesOperation(
                parentName: comp, errorContainer: errorContainer)

            // Decrypting messages can always run, no need to bail out early
            // if errors occurred earlier
            opDecrypt.bailOutEarlyOnError = false

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
        sendLayerDelegate?.didFetch(cdMessage: cdMessage)
    }

    func buildOperationLines(
        accountConnectInfos: [AccountConnectInfo],
        needsVerificationOnly: Bool = false) -> [OperationLine] {
        return accountConnectInfos.map {
            return buildOperationLine(
                accountInfo: $0, needsVerificationOnly: needsVerificationOnly)
        }
    }

    func scheduleOperationLineInternal(
        operationLine: OperationLine, completionBlock: (() -> Void)?) {
        let bgID = backgrounder?.beginBackgroundTask()
        operationLine.finalOperation.completionBlock = { [weak self, weak operationLine] in
            operationLine?.finalOperation.completionBlock = nil
            self?.backgrounder?.endBackgroundTask(bgID)
            completionBlock?()
        }
        for op in operationLine.operations {
            backgroundQueue.addOperation(op)
        }
    }

    /**
     Main entry point for the main loop.
     Implements RFC 4549 (https://tools.ietf.org/html/rfc4549).
     */
    func processAllInternal(repeatProcess: Bool = true, needsVerificationOnly: Bool = false) {
        if !cancelled {
            let connectInfos = gatherConnectInfos(needsVerificationOnly: needsVerificationOnly)
            let operationLines = buildOperationLines(
                accountConnectInfos: connectInfos, needsVerificationOnly: needsVerificationOnly)
            processOperationLinesInternal(operationLines: operationLines,
                                          repeatProcess: repeatProcess)
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
        let theComp = "\(comp) processOperationLinesInternal"
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
                    if let me = self, let theOl = ol {
                        Log.info(component: theComp,
                                 content: "didSync \(me.networkServiceDelegate)")
                        me.networkServiceDelegate?.didSync(
                            service: me, accountInfo: theOl.accountInfo,
                            errorProtocol: theOl.errorContainer)
                        // Process the rest
                        me.processOperationLines(operationLines: myLines)
                    }
                })
            } else {
                if repeatProcess {
                    workerQueue.asyncAfter(deadline: DispatchTime.now() + self.sleepTimeInSeconds) {
                        self.processAllInternal()
                    }
                }
            }
        } else {
            Log.verbose(component: theComp, content: "canceled with \(operationLines.count)")
        }
    }
}

extension NetworkService: SendLayerProtocol {
    public func verify(cdAccount account: CdAccount) {
        Log.info(component: comp, content: "verify")
        process(repeatProcess: false, needsVerificationOnly: true)
    }
}
