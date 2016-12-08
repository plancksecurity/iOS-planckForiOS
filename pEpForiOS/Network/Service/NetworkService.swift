//
//  NetworkService.swift
//  pEpForiOS
//
//  Created by hernani on 10/10/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import CoreData

import MessageModel

public protocol INetworkService {
}

public protocol NetworkServiceDelegate: class {
    /** Called after each account sync */
    func didSync(service: NetworkService, accountInfo: AccountConnectInfo)
}

/**
 * A thread class which provides an OO layer and doing syncing between CoreData and Pantomime
 * and any other (later) libraries providing in- and outbond transports of messages by managing
 * different background tasks and run loops (to be implemented).
 */
public class NetworkService: INetworkService {
    let comp = "NetworkService"

    let workerQueue = DispatchQueue(
        label: "net.pep-security.apps.pEp.service", qos: .utility, target: nil)
    let backgroundQueue = OperationQueue()

    var canceled = false
    var currentOperations = Set<Operation>()

    public weak var delegate: NetworkServiceDelegate?

    public init() {}

    /**
     Start endlessly synchronizing in the background.
     */
    public func start() {
        self.process()
    }

    /**
     Start endlessly synchronizing in the background.
     */
    public func process() {
        workerQueue.async {
            self.processAllInternal()
        }
    }

    /**
     Cancel all background operations, finish main loop.
     */
    public func cancel() {
        workerQueue.async {
            self.canceled = true
        }
    }

    func fetchValidatedAccounts(context: NSManagedObjectContext) -> [CdAccount] {
        return CdAccount.all(with: NSPredicate(format: "needsVerification = false"),
                             in: context)
            as? [CdAccount] ?? []
    }

    func gatherConnectInfos() -> [AccountConnectInfo] {
        var connectInfos = [AccountConnectInfo]()
        let context = Record.Context.background
        context.performAndWait {
            let accounts = self.fetchValidatedAccounts(context: context)
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

    func buildOperationLine(accountInfo: AccountConnectInfo) -> OperationLine {
        struct FolderInfo {
            let name: String
            let lastUID: UInt?
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
                    folderInfos.append(FolderInfo(name: name, lastUID: inboxFolder.lastUID()))
                }
            }
            if folderInfos.count == 0 {
                // If no interesting folders have been found, at least sync the inbox.
                folderInfos.append(FolderInfo(name: ImapSync.defaultImapInboxName,
                                              lastUID: nil))
            }
            return folderInfos
        }

        // Operation depending on all IMAP operations for this account
        let opImapFinished = BlockOperation(block: {
            Log.warn(component: self.comp, "IMAP sync finished")
        })

        // Operation depending on all SMTP operations for this account
        let opSmtpFinished = BlockOperation(block: {
            Log.warn(component: self.comp, "SMTP sync finished")
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
            var lastFetchMessagesOp: Operation? = nil
            for fi in folderInfos {
                let fetchMessagesOp = FetchMessagesOperation(imapSyncData: imapSyncData,
                                                             folderName: fi.name)
                operations.append(fetchMessagesOp)
                fetchMessagesOp.addDependency(opFetchFolders)
                opImapFinished.addDependency(fetchMessagesOp)
                if let op = lastFetchMessagesOp {
                    fetchMessagesOp.addDependency(op)
                }
                lastFetchMessagesOp = fetchMessagesOp
            }

            // sync existing messages
            // TODO
        }

        // ...

        return OperationLine(accountInfo: accountInfo, operations: operations,
                             finalOperation: opAllFinished)
    }

    func buildOperationLines(accountConnectInfos: [AccountConnectInfo]) -> [OperationLine] {
        return accountConnectInfos.map { return buildOperationLine(accountInfo: $0) }
    }

    func scheduleOperationLine(operationLine: OperationLine, completionBlock: (() -> Void)?) {
        operationLine.finalOperation.completionBlock = completionBlock
        for op in operationLine.operations {
            backgroundQueue.addOperation(op)
        }
    }

    /**
     Main entry point for the main loop.
     Implements RFC 4549 (https://tools.ietf.org/html/rfc4549).
     */
    func processAllInternal() {
        if !canceled {
            let connectInfos = gatherConnectInfos()
            let operationLines = buildOperationLines(accountConnectInfos: connectInfos)
            processOperationLinesInternal(operationLines: operationLines)
        }
    }

    func processOperationLines(operationLines: [OperationLine]) {
        workerQueue.async {
            self.processOperationLinesInternal(operationLines: operationLines)
        }
    }

    func processOperationLinesInternal(operationLines: [OperationLine]) {
        var myLines = operationLines
        if myLines.first != nil {
            let ol = myLines.removeFirst()
            scheduleOperationLine(operationLine: ol, completionBlock: {
                self.delegate?.didSync(service: self, accountInfo: ol.accountInfo)
                // Process the rest
                self.processOperationLines(operationLines: myLines)
            })
        } else {
            processAllInternal()
        }
    }
}
