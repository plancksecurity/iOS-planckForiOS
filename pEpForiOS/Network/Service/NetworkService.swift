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
        label: "net.pep-security.apps.pEp.service", qos: .background, target: nil)
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

        // 3.a Items not associated with any mailbox (e.g., SMTP send)

        if let imapCI = accountInfo.imapConnectInfo {
            let imapSyncData = ImapSyncData(connectInfo: imapCI)
            // login IMAP
            let opLogin = LoginImapOperation(imapSyncData: imapSyncData)
            opImapFinished.addDependency(opLogin)
            operations.append(opLogin)

            // 3.b Fetch current list of interesting mailboxes
            let opFetchFolders = FetchFoldersOperation(imapSyncData: imapSyncData)
            operations.append(opFetchFolders)
            opFetchFolders.addDependency(opLogin)
            opImapFinished.addDependency(opFetchFolders)
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
