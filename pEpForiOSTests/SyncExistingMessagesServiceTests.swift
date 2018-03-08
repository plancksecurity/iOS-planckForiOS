//
//  SyncExistingMessagesServiceTests.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 06.07.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import MessageModel
@testable import pEpForiOS

class SyncExistingMessagesServiceTests: XCTestCase {
    var persistentSetup: PersistentSetup!

    var cdAccount: CdAccount!

    override func setUp() {
        super.setUp()
        persistentSetup = PersistentSetup()

        let cdAccount = SecretTestData().createWorkingCdAccount()
        TestUtil.skipValidation()
        Record.saveAndWait()
        self.cdAccount = cdAccount
    }

    func runSyncTest(parentName: String, folderName: String = ImapSync.defaultImapInboxName,
                     useDisfunctionalAccount: Bool, expectError: Bool) {
        // the fetch should actually always work
        TestUtil.runFetchTest(parentName: parentName, testCase: self, cdAccount: cdAccount,
                              useDisfunctionalAccount: false,
                              folderName:  ImapSync.defaultImapInboxName,
                              expectError: false)

        if useDisfunctionalAccount {
            TestUtil.makeServersUnreachable(cdAccount: cdAccount)
        }

        guard let (imapSyncData, _) = TestUtil.syncData(cdAccount: cdAccount) else {
            XCTFail()
            return
        }

        let expectationBackgrounded = expectation(description: "expectationBackgrounded")
        let mbg = MockBackgrounder(expBackgroundTaskFinishedAtLeastOnce: expectationBackgrounded)
        let service = SyncExistingMessagesService(
            parentName: #function, backgrounder: mbg, imapSyncData: imapSyncData,
            folderName: folderName)

        service.execute() { error in
            if expectError {
                XCTAssertNotNil(error)
            } else {
                XCTAssertNil(error)
            }
        }

        waitForExpectations(timeout: TestUtil.waitTime) { error in
            XCTAssertNil(error)
        }
    }

    func testAfterFetchingOK() {
        runSyncTest(parentName: #function, folderName: "INbox", useDisfunctionalAccount: false,
                    expectError: false)
    }

    func testAfterFetchingError() {
        runSyncTest(parentName: #function, folderName: "inbox", useDisfunctionalAccount: true,
                    expectError: true)
    }

    func testWrongFolder() {
        runSyncTest(parentName: #function, folderName: "wrongDoesNotExist",
                    useDisfunctionalAccount: false, expectError: true)
    }
}
