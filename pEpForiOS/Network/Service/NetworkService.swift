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
    func didSync(service: NetworkService, accountInfo: AccountConnectInfo)

    /** Called after all operations have been canceled */
    func didCancel(service: NetworkService)
}

/**
 * A thread class which provides an OO layer and doing syncing between CoreData and Pantomime
 * and any other (later) libraries providing in- and outbond transports of messages by managing
 * different background tasks and run loops (to be implemented).
 */
public class NetworkService: INetworkService {
    let comp = "NetworkService"

    public var sendLayerDelegate: SendLayerDelegate?

    /**
     Amount of time to "sleep" between complete syncs of all accounts.
     */
    let sleepTimeInSeconds: Double

    let workerQueue = DispatchQueue(
        label: "NetworkService", qos: .utility, target: nil)
    let backgroundQueue = OperationQueue()

    var cancelled = false
    var currentOperations = Set<Operation>()

    public weak var networkServiceDelegate: NetworkServiceDelegate?

    let parentName: String?

    let backgrounder: BackgroundTaskProtocol?
    let mySelfer: KickOffMySelfProtocol?

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
            Log.info(component: self.comp, content: "cancel()")
            self.cancelled = true
            self.backgroundQueue.cancelAllOperations()
            Log.info(component: self.comp, content: "all operations cancelled")
            self.backgroundQueue.waitUntilAllOperationsAreFinished()
            self.networkServiceDelegate?.didCancel(service: self)
        }
    }

    func fetchAccounts(
        context: NSManagedObjectContext, needsVerificationOnly: Bool = false) -> [CdAccount] {
        let p = NSPredicate(format: "needsVerification = %@",
                            NSNumber(booleanLiteral: needsVerificationOnly))
        return CdAccount.all(with: p, in: context) as? [CdAccount] ?? []
    }

    func gatherConnectInfos(needsVerificationOnly: Bool = false) -> [AccountConnectInfo] {
        var connectInfos = [AccountConnectInfo]()
        let context = Record.Context.background
        context.performAndWait {
            let accounts = self.fetchAccounts(
                context: context, needsVerificationOnly: needsVerificationOnly)
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
            let context = Record.Context.background
            context.performAndWait {
                guard let account = context.object(with: accountInfo.accountID) as? CdAccount else {
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
                    Record.saveAndWait(context: context)
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

    func buildOperationLine(
        accountInfo: AccountConnectInfo, needsVerificationOnly: Bool) -> OperationLine {
        struct FolderInfo {
            let name: String
            let lastUID: UInt?
            let folderID: NSManagedObjectID?
        }

        /**
         Determine "interesting" folder names that should be synced, and for each:
         Determine current lastUID, and store it (for later sync of existing messages).
         - Note: Interesting mailboxes are Inbox (always), and the most recently looked at
         folders (see lastLookedAt, IOS-291).
         */
        func determineInterestingFolders() -> [FolderInfo] {
            var folderInfos = [FolderInfo]()
            let context = Record.Context.background
            context.performAndWait {
                guard let account = context.object(with: accountInfo.accountID) as? CdAccount else {
                    return
                }

                // Currently, the only interesting mailbox is Inbox.
                if let inboxFolder = CdFolder.by(folderType: .inbox, account: account) {
                    let name = inboxFolder.name ?? ImapSync.defaultImapInboxName
                    folderInfos.append(FolderInfo(name: name, lastUID: inboxFolder.lastUID(),
                                                  folderID: inboxFolder.objectID))
                }
            }
            if folderInfos.count == 0 {
                // If no interesting folders have been found, at least sync the inbox.
                folderInfos.append(FolderInfo(name: ImapSync.defaultImapInboxName,
                                              lastUID: nil, folderID: nil))
            }
            return folderInfos
        }

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

        var opSmtpLoginOpt: BaseOperation?
        if let smtpCI = accountInfo.smtpConnectInfo {
            // 3.a Items not associated with any mailbox (e.g., SMTP send)
            let smtpSendData = SmtpSendData(connectInfo: smtpCI)
            let opSmtpLogin = LoginSmtpOpration(smtpSendData: smtpSendData)
            opSmtpLogin.completionBlock = { [weak self] in
                if let me = self {
                    me.workerQueue.async {
                        Log.info(component: me.comp, content: "opSmtpLogin finished")
                    }
                }
            }
            opSmtpLoginOpt = opSmtpLogin
            opSmtpFinished.addDependency(opSmtpLogin)
            operations.append(opSmtpLogin)
        }

        if let imapCI = accountInfo.imapConnectInfo {
            // TODO: Reuse connections
            let imapSyncData = ImapSyncData(connectInfo: imapCI)

            // login IMAP
            // TODO: Check if needed
            let opImapLogin = LoginImapOperation(imapSyncData: imapSyncData, name: parentName)
            opImapLogin.completionBlock = { [weak self, weak opImapLogin] in
                self?.workerQueue.async {
                    if let me = self, let theOpImapLogin = opImapLogin {
                        var ops: [BaseOperation] = [theOpImapLogin]
                        if let op = opSmtpLoginOpt {
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
                parentName: parentName, imapSyncData: imapSyncData)
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

            // 3.d Server-to-client synchronization (IMAP)

            let folderInfos = determineInterestingFolders()

            // sync new messages
            var lastImapOp: Operation? = nil
            for fi in folderInfos {
                let fetchMessagesOp = FetchMessagesOperation(
                parentName: parentName, imapSyncData: imapSyncData, folderName: fi.name) {
                    [weak self] message in self?.messageFetched(cdMessage: message)
                }
                self.workerQueue.async {
                    Log.info(component: self.comp, content: "fetchMessagesOp finished")
                }
                operations.append(fetchMessagesOp)
                fetchMessagesOp.addDependency(opFetchFolders)
                opImapFinished.addDependency(fetchMessagesOp)
                if let op = lastImapOp {
                    fetchMessagesOp.addDependency(op)
                }
                lastImapOp = fetchMessagesOp
            }

            let opDecrypt = DecryptMessageOperation(parentName: comp)
            if let lastImap = lastImapOp {
                opDecrypt.addDependency(lastImap)
            }
            opImapFinished.addDependency(opDecrypt)
            operations.append(opDecrypt)

            // sync existing messages
            for fi in folderInfos {
                if let folderID = fi.folderID, let lastUID = fi.lastUID {
                    let syncMessagesOp = SyncMessagesOperation(
                        parentName: parentName, imapSyncData: imapSyncData,
                        folderID: folderID, folderName: fi.name, lastUID: lastUID)
                    syncMessagesOp.completionBlock = { [weak self] in
                        if let me = self {
                            Log.info(component: me.comp, content: "syncMessagesOp finished")
                        }
                    }
                    if let lastOp = lastImapOp {
                        syncMessagesOp.addDependency(lastOp)
                    }
                    operations.append(syncMessagesOp)
                    opImapFinished.addDependency(syncMessagesOp)
                    lastImapOp = syncMessagesOp
                }
            }
        }

        // ...

        operations.append(contentsOf: [opSmtpFinished, opImapFinished, opAllFinished])

        return OperationLine(accountInfo: accountInfo, operations: operations,
                             finalOperation: opAllFinished, errorContainer: errorContainer)
    }

    func messageFetched(cdMessage: CdMessage) {
        if let mid = cdMessage.messageID {
            sendLayerDelegate?.didFetchMessage(messageID: mid)
        }
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
        operationLine.finalOperation.completionBlock = { [weak self] in
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
        workerQueue.async {
            self.processOperationLinesInternal(operationLines: operationLines)
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
                        me.networkServiceDelegate?.didSync(
                            service: me, accountInfo: theOl.accountInfo)
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
