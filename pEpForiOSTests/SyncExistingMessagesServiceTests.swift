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

        let cdAccount = TestData().createWorkingCdAccount()
        cdAccount.identity?.isMySelf = true
        TestUtil.skipValidation()
        Record.saveAndWait()
        self.cdAccount = cdAccount
    }

    func runSyncTest(folderName: String = ImapSync.defaultImapInboxName,
                     useDisfunctionalAccount: Bool, expectError: Bool) {
        // the fetch should actually always work
        TestUtil.runFetchTest(testCase: self, cdAccount: cdAccount,
                              useDisfunctionalAccount: false,
                              folderName:  ImapSync.defaultImapInboxName,
                              expectError: false)

        let expectationBackgrounded = expectation(description: "expectationBackgrounded")
        let mbg = MockBackgrounder(expBackgroundTaskFinishedAtLeastOnce: expectationBackgrounded)
        let service = SyncExistingMessagesService(parentName: #function, backgrounder: mbg)

        if useDisfunctionalAccount {
            TestUtil.makeServersUnreachable(cdAccount: cdAccount)
        }

        guard let (imapSyncData, _) = TestUtil.syncData(cdAccount: cdAccount) else {
            XCTFail()
            return
        }

        service.execute(imapSyncData: imapSyncData, folderName: folderName) { error in
            if expectError {
                XCTAssertNotNil(error)
            } else {
                XCTAssertNil(error)
            }
        }

        waitForExpectations(timeout: TestUtil.waitTimeForever) { error in
            XCTAssertNil(error)
        }
    }

    func testAfterFetchingOK() {
        runSyncTest(folderName: "INbox", useDisfunctionalAccount: false, expectError: false)
    }

    func testAfterFetchingError() {
        runSyncTest(folderName: "inbox", useDisfunctionalAccount: true, expectError: true)
    }

    func testWrongFolder() {
        runSyncTest(folderName: "wrongDoesNotExist",
                    useDisfunctionalAccount: false, expectError: true)
    }
}
