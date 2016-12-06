//
//  NetworkService.swift
//  pEpForiOS
//
//  Created by hernani on 10/10/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import CoreData

import MessageModel

protocol INetworkService {
}

/**
 * A thread class which provides an OO layer and doing syncing between CoreData and Pantomime
 * and any other (later) libraries providing in- and outbond transports of messages by managing
 * different background tasks and run loops (to be implemented).
 */
public class NetworkService: INetworkService {
    let comp = "NetworkService"

    let workerQueue = DispatchQueue(label: "net.pep-security.apps.pEp.service", qos: .background,
                                    target: nil)
    var canceled = false
    var currentOperations = Set<Operation>()

    public init() {}

    /**
     Start endlessly synchronizing in the background.
     */
    public func start() {
        workerQueue.async {
            self.process()
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

    func buildOperationLine(accountConnectInfos: [AccountConnectInfo]) -> [Operation] {
        // Operation depending on all IMAP operations for this account
        let opImapFinished = Operation()

        // Operation depending on all SMTP operations for this account
        let opSmtpFinished = Operation()

        // Operation depending on all IMAP and SMTP operations
        let opAllFinished = Operation()
        opAllFinished.addDependency(opImapFinished)
        opAllFinished.addDependency(opSmtpFinished)

        var operations = [opImapFinished, opSmtpFinished, opAllFinished]
        let imapSyncData = ImapSyncData()

        for ai in accountConnectInfos {
            // login IMAP
            if let imapCI = ai.imapConnectInfo {
                let op = LoginImapOperation(connectInfo: imapCI, imapSyncData: imapSyncData)
                opImapFinished.addDependency(op)
                operations.append(op)
            }

            // 3.a Items not associated with any mailbox (e.g., SMTP send)

            // 3.b Fetch current list of interesting mailboxes

            // ...
        }
        return operations
    }

    /**
     Main entry point for the main loop.
     Implements RFC 4549 (https://tools.ietf.org/html/rfc4549).
     */
    func process() {
        let connectInfos = gatherConnectInfos()
    }
}
