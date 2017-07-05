//
//  FetchMessagesServiceTests.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 05.07.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import MessageModel
@testable import pEpForiOS

class FetchMessagesServiceTests: XCTestCase {
    var persistentSetup: PersistentSetup!

    var cdAccount: CdAccount!
    var cdAccountDisfunctional: CdAccount!

    class TestDelegate: FetchMessagesServiceDelegate {
        var fetchedMessages = [Message]()

        func didFetch(message: Message) {
            fetchedMessages.append(message)
        }
    }

    override func setUp() {
        super.setUp()
        persistentSetup = PersistentSetup()

        let cdAccount = TestData().createWorkingCdAccount()
        cdAccount.identity?.isMySelf = true
        TestUtil.skipValidation()
        Record.saveAndWait()
        self.cdAccount = cdAccount

        let cdDisfunctionalAccount = TestData().createDisfunctionalCdAccount()
        cdDisfunctionalAccount.identity?.isMySelf = true
        TestUtil.skipValidation()
        Record.saveAndWait()
        self.cdAccountDisfunctional = cdDisfunctionalAccount
    }

    func runFetchTest(
        useDisfunctionalAccount: Bool,
        folderName: String = ImapSync.defaultImapInboxName,
        expectError: Bool) {
        let expectationServiceRan = expectation(description: "expectationServiceRan")
        let mbg = MockBackgrounder(expBackgroundTaskFinishedAtLeastOnce: expectationServiceRan)
        let service = FetchMessagesService(parentName: #function, backgrounder: mbg)
        let testDelegate = TestDelegate()
        service.delegate = testDelegate

        if useDisfunctionalAccount {
            TestUtil.makeServersUnreachable(cdAccount: cdAccount)
        }

        guard let (imapSyncData, _) = TestUtil.syncData(cdAccount: cdAccount) else {
            XCTFail()
            return
        }

        let expServiceBlockInvoked = expectation(description: "expServiceBlockInvoked")
        service.execute(imapSyncData: imapSyncData, folderName: folderName) { error in
            expServiceBlockInvoked.fulfill()

            if useDisfunctionalAccount || expectError {
                XCTAssertNotNil(error)
            } else {
                XCTAssertNil(error)
            }
        }

        waitForExpectations(timeout: TestUtil.waitTime) { error in
            XCTAssertNil(error)
        }

        if useDisfunctionalAccount || expectError {
            XCTAssertEqual(testDelegate.fetchedMessages.count, 0)
        } else {
            XCTAssertGreaterThan(testDelegate.fetchedMessages.count, 0)
        }
    }

    func testBasicFetchOK() {
        runFetchTest(useDisfunctionalAccount: false, folderName: "inBOX", expectError: false)
    }

    func testBasicFetchAccountError() {
        runFetchTest(useDisfunctionalAccount: true, folderName: "inBOX", expectError: false)
    }

    func testBasicFetchError() {
        runFetchTest(useDisfunctionalAccount: false, folderName: "inBOXeZZZZ", expectError: true)
    }
}
