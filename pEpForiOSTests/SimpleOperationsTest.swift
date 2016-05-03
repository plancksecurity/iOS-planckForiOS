//
//  SimpleOperationsTest.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 03/05/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import XCTest
import CoreData

import pEpForiOS

class SimpleOperationsTest: XCTestCase {
    let waitTime: NSTimeInterval = 10

    let coreDataUtil = InMemoryCoreDataUtil.init()
    var persistentSetup: PersistentSetup!
    var grandOperator: IGrandOperator!
    var connectInfo: ConnectInfo!

    override func setUp() {
        super.setUp()
        persistentSetup = PersistentSetup.init(coreDataUtil: coreDataUtil)
        grandOperator = GrandOperator.init(connectionManager: ConnectionManager.init(),
                                           coreDataUtil: coreDataUtil)
        connectInfo = TestData.connectInfo
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testPrefetchMailsOperation() {
        let mailsPrefetched = expectationWithDescription("mailsPrefetched")

        let op = PrefetchEmailsOperation.init(grandOperator: grandOperator,
                                              connectInfo: connectInfo,
                                              folder: ImapSync.defaultImapInboxName)
        op.completionBlock = {
            mailsPrefetched.fulfill()
        }

        op.start()
        waitForExpectationsWithTimeout(waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertGreaterThan(
                self.grandOperator.model.folderCountByPredicate(NSPredicate.init(value: true)), 1)
            XCTAssertGreaterThan(
                self.grandOperator.model.messageCountByPredicate(NSPredicate.init(value: true)), 1)
        })
    }

    func testFetchFoldersOperation() {
        let foldersFetched = expectationWithDescription("foldersFetched")

        let op = FetchFoldersOperation.init(grandOperator: grandOperator,
                                            connectInfo: connectInfo,
                                            folder: ImapSync.defaultImapInboxName)
        op.completionBlock = {
            foldersFetched.fulfill()
        }

        op.start()
        waitForExpectationsWithTimeout(waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertGreaterThan(
                self.grandOperator.model.folderCountByPredicate(NSPredicate.init(value: true)), 1)
        })
    }
}
