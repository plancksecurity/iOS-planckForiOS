 //
//  ServiceChainExecutorTests.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 07.07.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import MessageModel
@testable import pEpForiOS

class ServiceChainExecutorTests: XCTestCase {
    var persistentSetup: PersistentSetup!

    var cdAccount: CdAccount!
    var cdAccountDisfunctional: CdAccount!

    override func setUp() {
        super.setUp()
        persistentSetup = PersistentSetup()

        let cdAccount = SecretTestData().createWorkingCdAccount()
        TestUtil.skipValidation()
        Record.saveAndWait()
        self.cdAccount = cdAccount
    }

    func runServices(useDisfunctionalAccount: Bool, expectError: Bool) {
        guard let theCdAccount = cdAccount else {
            XCTFail()
            return
        }

        let outgoingMailsToSend = TestUtil.createOutgoingMails(
            cdAccount: theCdAccount, testCase: self, numberOfMails: 3)
        XCTAssertGreaterThan(outgoingMailsToSend.count, 0)

        if useDisfunctionalAccount {
            TestUtil.makeServersUnreachable(cdAccount: theCdAccount)
        }

        guard let (imapSyncData, smtpSendData) = TestUtil.syncData(cdAccount: theCdAccount) else {
            XCTFail()
            return
        }

        let expBackgroundAllTasksBackgrounded: XCTestExpectation? = expectError ? nil : expectation(
            description: "expBackgroundAllTasksBackgrounded")
        expBackgroundAllTasksBackgrounded?.assertForOverFulfill = true
        expBackgroundAllTasksBackgrounded?.expectedFulfillmentCount = 4
        let backgrounder = MockBackgrounder(
            expBackgroundTaskFinishedAtLeastOnce: expBackgroundAllTasksBackgrounded)

        let smtpSentDelegate = TestSmtpSendServiceDelegate()
        let smtpService = SmtpSendService(
            parentName: #function, backgrounder: backgrounder,
            imapSyncData: imapSyncData, smtpSendData: smtpSendData)
        smtpService.delegate = smtpSentDelegate

        let fetchFoldersService = FetchFoldersService(
            parentName: #function, backgrounder: backgrounder, imapSyncData: imapSyncData)

        let fetchMessagesService = FetchMessagesService(
            parentName: #function, backgrounder: backgrounder, imapSyncData: imapSyncData)

        let syncMessagesService = SyncExistingMessagesService(
            parentName: #function, backgrounder: backgrounder, imapSyncData: imapSyncData)

        let chainedService = ServiceChainExecutor()
        chainedService.add(services: [smtpService, fetchFoldersService,
                                      fetchMessagesService, syncMessagesService])

        let expectationAllServicesExecuted = expectation(
            description: "expectationAllServicesExecuted")
        chainedService.execute() { error in
            if error == nil {
                XCTAssertEqual(smtpSentDelegate.successfullySentMessageIDs.count,
                               outgoingMailsToSend.count)
            } else {
                XCTAssertLessThan(smtpSentDelegate.successfullySentMessageIDs.count,
                                  outgoingMailsToSend.count)
            }

            if expectError {
                XCTAssertNotNil(error)
            } else {
                XCTAssertNil(error)
            }

            expectationAllServicesExecuted.fulfill()
        }
        waitForExpectations(timeout: TestUtil.waitTime) { error in
            XCTAssertNil(error)
        }
    }

    func testBasicOK() {
        runServices(useDisfunctionalAccount: false, expectError: false)
    }

    func testBasicError() {
        runServices(useDisfunctionalAccount: true, expectError: true)
    }
}
