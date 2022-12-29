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
    public func loginIMAP(imapConnection: ImapConnectionProtocol,
                          errorContainer: ErrorContainerProtocol,
                          queue: OperationQueue,
                          context: NSManagedObjectContext? = nil) {
        let expImapLoggedIn = expectation(description: "expImapLoggedIn")

        let imapLogin = LoginImapOperation(parentName: #function,
                                           context: context,
                                           errorContainer: errorContainer,
                                           imapConnection: imapConnection)
        imapLogin.completionBlock = {
            imapLogin.completionBlock = nil
            expImapLoggedIn.fulfill()
        }
        queue.addOperation(imapLogin)

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertFalse(imapLogin.hasErrors)
        })
    }

    public func fetchFoldersIMAP(imapConnection: ImapConnectionProtocol,
                                 queue: OperationQueue) {
        let expFoldersFetched = expectation(description: "expFoldersFetched")
        let syncFoldersOp = SyncFoldersFromServerOperation(parentName: #function,
                                                           imapConnection: imapConnection)
        syncFoldersOp.completionBlock = {
            syncFoldersOp.completionBlock = nil
            expFoldersFetched.fulfill()
        }

        queue.addOperation(syncFoldersOp)

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertFalse(syncFoldersOp.hasErrors)
        })
    }

    func appendMailsIMAP(folder: CdFolder,
                         imapConnection: ImapConnectionProtocol,
                         errorContainer: ErrorContainerProtocol,
                         queue: OperationQueue) {
        let expSentAppended = expectation(description: "expSentAppended")
        let appendOp = AppendMailsToFolderOperation(parentName: #function,
                                                    folder: folder,
                                                    errorContainer: errorContainer,
                                                    imapConnection: imapConnection)
        appendOp.completionBlock = {
            appendOp.completionBlock = nil
            expSentAppended.fulfill()
        }

        queue.addOperation(appendOp)

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertFalse(appendOp.hasErrors)
        })
    }

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

    public func fetchNumberOfNewMails(errorContainer: ErrorContainerProtocol,
                                      context: NSManagedObjectContext) -> Int? {
        let expNumMails = expectation(description: "expNumMails")
        var numMails: Int?
        let fetchNumMailsOp = FetchNumberOfNewMailsService(imapConnectionDataCache: nil,
                                                           context: context)
        fetchNumMailsOp.start() { theNumMails in
            numMails = theNumMails
            expNumMails.fulfill()
        }

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertNotNil(numMails)
            XCTAssertNil(errorContainer.error)
        })

        return numMails
    }
}
