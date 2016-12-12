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

    /**
     Amount of time to "sleep" between complete syncs of all accounts.
     */
    let sleepTimeInSeconds: Double

    let workerQueue = DispatchQueue(
        label: "net.pep-security.apps.pEp.service", qos: .utility, target: nil)
    let backgroundQueue = OperationQueue()

    var canceled = false
    var currentOperations = Set<Operation>()

    public weak var delegate: NetworkServiceDelegate?

    public init(sleepTimeInSeconds: Double = 5.0) {
        self.sleepTimeInSeconds = sleepTimeInSeconds
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
            self.canceled = true
            self.delegate?.didCancel(service: self)
            for op in self.backgroundQueue.operations {
                op.cancel()
            }
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

    func checkVerified(accountInfo: AccountConnectInfo, needsVerificationOnly: Bool) {
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

        // Operation depending on all IMAP operations for this account
        let opImapFinished = BlockOperation(block: {
            Log.warn(component: self.comp, content: "IMAP sync finished")
        })

        // Operation depending on all SMTP operations for this account
        let opSmtpFinished = BlockOperation(block: {
            Log.warn(component: self.comp, content: "SMTP sync finished")
        })

        // Operation depending on all IMAP and SMTP operations
        let opAllFinished = Operation()
        opAllFinished.addDependency(opImapFinished)
        opAllFinished.addDependency(opSmtpFinished)

        var operations = [opImapFinished, opSmtpFinished, opAllFinished]

        if let _ = accountInfo.smtpConnectInfo {
            // 3.a Items not associated with any mailbox (e.g., SMTP send)
        }

        if let imapCI = accountInfo.imapConnectInfo {
            // TODO: Reuse connections
            let imapSyncData = ImapSyncData(connectInfo: imapCI)

            // login IMAP
            // TODO: Check if needed
            let opLogin = LoginImapOperation(imapSyncData: imapSyncData)
            opLogin.completionBlock = {
                self.checkVerified(accountInfo: accountInfo,
                                   needsVerificationOnly: needsVerificationOnly)
            }
            opImapFinished.addDependency(opLogin)
            operations.append(opLogin)

            // 3.b Fetch current list of interesting mailboxes
            let opFetchFolders = FetchFoldersOperation(imapSyncData: imapSyncData)
            operations.append(opFetchFolders)
            opFetchFolders.addDependency(opLogin)
            opImapFinished.addDependency(opFetchFolders)

            // 3.c Client-to-server synchronization (IMAP)

            // 3.d Server-to-client synchronization (IMAP)

            let folderInfos = determineInterestingFolders()

            // sync new messages
            var lastImapOp: Operation? = nil
            for fi in folderInfos {
                let fetchMessagesOp = FetchMessagesOperation(
                    imapSyncData: imapSyncData, folderName: fi.name)
                operations.append(fetchMessagesOp)
                fetchMessagesOp.addDependency(opFetchFolders)
                opImapFinished.addDependency(fetchMessagesOp)
                if let op = lastImapOp {
                    fetchMessagesOp.addDependency(op)
                }
                lastImapOp = fetchMessagesOp
            }

            // sync existing messages
            for fi in folderInfos {
                if let folderID = fi.folderID, let lastUID = fi.lastUID {
                    let syncMessagesOp = SyncMessagesOperation(
                        imapSyncData: imapSyncData, folderID: folderID, folderName: fi.name,
                        lastUID: lastUID)
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

        return OperationLine(accountInfo: accountInfo, operations: operations,
                             finalOperation: opAllFinished)
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
        operationLine.finalOperation.completionBlock = completionBlock
        for op in operationLine.operations {
            backgroundQueue.addOperation(op)
        }
    }

    /**
     Main entry point for the main loop.
     Implements RFC 4549 (https://tools.ietf.org/html/rfc4549).
     */
    func processAllInternal(repeatProcess: Bool = true, needsVerificationOnly: Bool = false) {
        if !canceled {
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
        if !self.canceled {
            var myLines = operationLines
            if myLines.first != nil {
                let ol = myLines.removeFirst()
                scheduleOperationLineInternal(operationLine: ol, completionBlock: {
                    self.delegate?.didSync(service: self, accountInfo: ol.accountInfo)
                    // Process the rest
                    self.processOperationLines(operationLines: myLines)
                })
            } else {
                if repeatProcess {
                    workerQueue.asyncAfter(deadline: DispatchTime.now() + self.sleepTimeInSeconds) {
                        self.processAllInternal()
                    }
                }
            }
        }
    }
}

extension NetworkService: SendLayerProtocol {
    public func verify(account: CdAccount,
                       completionBlock: SendLayerCompletionBlock?) {
        process(repeatProcess: false, needsVerificationOnly: true)
    }

    public func send(message: CdMessage, completionBlock: SendLayerCompletionBlock?) {
        assertionFailure("NetworkService.send not implemented")
    }

    public func saveDraft(message: CdMessage,
                          completionBlock: SendLayerCompletionBlock?) {
        assertionFailure("NetworkService.saveDraft not implemented")
    }

    public func syncFlagsToServer(folder: CdFolder,
                                  completionBlock: SendLayerCompletionBlock?) {
        assertionFailure("NetworkService.syncFlagsToServer not implemented")
    }

    public func create(folderType: FolderType, account: CdAccount,
                       completionBlock: SendLayerCompletionBlock?) {
        assertionFailure("NetworkService.create(folderType:) not implemented")
    }

    public func delete(folder: CdFolder, completionBlock: SendLayerCompletionBlock?) {
        assertionFailure("NetworkService.delete(folder:) not implemented")
    }

    public func delete(message: CdMessage,
                       completionBlock: SendLayerCompletionBlock?) {
        assertionFailure("NetworkService.delete(message:) not implemented")
    }
}
