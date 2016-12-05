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

    func fetchValidatedAccounts() -> [CdAccount] {
        return CdAccount.all(with: NSPredicate(format: "needsVerification = false"))
            as? [CdAccount] ?? []
    }

    /**
     Main entry point for the main loop.
     Implements RFC 4549 (https://tools.ietf.org/html/rfc4549).
     */
    func process() {
        let accounts = fetchValidatedAccounts()

        for acc in accounts {
            // 3.a Items not associated with any mailbox (e.g., SMTP send)
            if let _ = acc.smtpConnectInfo {
                // TODO
            }

            // 3.b Fetch current list of interesting mailboxes
        }
    }
}
