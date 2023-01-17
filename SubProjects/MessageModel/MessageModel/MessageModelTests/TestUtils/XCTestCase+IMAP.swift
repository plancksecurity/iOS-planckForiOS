//
//  XCTestCase+IMAP.swift
//  MessageModelTests
//
//  Created by Dirk Zimmermann on 11.06.20.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import Foundation
import XCTest
import CoreData

@testable import MessageModel

extension XCTestCase {
    // MARK: - Sync Loop

    public func syncAndWait(cdAccountsToSync:[CdAccount]? = nil,
                            context: NSManagedObjectContext? = nil) {

        let context: NSManagedObjectContext = context ?? Stack.shared.mainContext

        guard let accounts = cdAccountsToSync ?? CdAccount.all(in: context) as? [CdAccount] else {
            XCTFail("No account to sync")
            return
        }

        // Serial queue
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1

        let errorPropagator = ErrorPropagator()

        // Array to own services as long as they are in use.
        var services = [ServiceProtocol]()

        for cdaccount in accounts {
            // Send all
            guard let sendService = cdaccount.sendService(errorPropagator: errorPropagator) else {
                // This account does not offer a send send service. That might be a valid case for
                // protocols supported in the future.
                continue
            }
            services.append(sendService)
            queue.addOperations(sendService.operations(), waitUntilFinished: false)

            // Fetch & Sync all
            guard
                let replicationService = cdaccount.replicationService(errorPropagator: errorPropagator)
                else {
                // This account does not offer a replication send service. That might be a valid case for
                // protocols supported in the future.
                continue
            }
            services.append(replicationService)
            queue.addOperations(replicationService.operations(), waitUntilFinished: false)
        }

        // Decrypt all
        let decryptService = DecryptService(errorPropagator: errorPropagator)
        services.append(decryptService)
        queue.addOperations(decryptService.operations(), waitUntilFinished: false)


        let expSynced = expectation(description: "expSynced")
        DispatchQueue.global(qos: .utility).async {
            queue.waitUntilAllOperationsAreFinished()
            expSynced.fulfill()
        }

        wait(for: [expSynced], timeout: TestUtil.waitTime)
    }
}
