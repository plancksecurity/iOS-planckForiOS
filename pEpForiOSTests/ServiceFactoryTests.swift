//
//  ServiceFactoryTests.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 10.07.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import MessageModel
@testable import pEpForiOS

class ServiceFactoryTests: XCTestCase {
    var persistentSetup: PersistentSetup!

    var cdAccount: CdAccount!
    var cdAccountDisfunctional: CdAccount!

    override func setUp() {
        super.setUp()
        persistentSetup = PersistentSetup()

        let cdAccount = TestData().createWorkingCdAccount()
        cdAccount.identity?.isMySelf = true
        TestUtil.skipValidation()
        Record.saveAndWait()
        self.cdAccount = cdAccount
    }

    func runServices(functionName: String, useDisfunctionalAccount: Bool, expectError: Bool) {
        guard let theCdAccount = cdAccount else {
            XCTFail()
            return
        }

        let outgoingMailsToSend = TestUtil.createOutgoingMails(
            cdAccount: theCdAccount, testCase: self, numberOfMails: 3)
        XCTAssertGreaterThan(outgoingMailsToSend.count, 0)

        let cdMessagesBefore = EncryptAndSendOperation.outgoingMails(
            context: Record.Context.default, cdAccount: cdAccount)
        XCTAssertEqual(cdMessagesBefore.count, outgoingMailsToSend.count)

        if useDisfunctionalAccount {
            TestUtil.makeServersUnreachable(cdAccount: theCdAccount)
        }

        guard let (imapSyncData, smtpSendData) = TestUtil.syncData(cdAccount: theCdAccount) else {
            XCTFail()
            return
        }

        let expBackgroundAllTasksBackgrounded: XCTestExpectation? =
            expectError ? nil : expectation(description: "expBackgroundAllTasksBackgrounded")
        expBackgroundAllTasksBackgrounded?.assertForOverFulfill = true
        expBackgroundAllTasksBackgrounded?.expectedFulfillmentCount = 5
        let backgrounder = MockBackgrounder(
            expBackgroundTaskFinishedAtLeastOnce: expBackgroundAllTasksBackgrounded)

        let serviceFactory = ServiceFactory()
        let smtpSentDelegate = TestSmtpSendServiceDelegate()
        let service = serviceFactory.initialSync(
            parentName: functionName, backgrounder: backgrounder,
            imapSyncData: imapSyncData, smtpSendData: smtpSendData,
            smtpSendServiceDelegate: smtpSentDelegate, syncFlagsToServerServiceDelegate: nil)

        let expectationAllServicesExecuted = expectation(
            description: "expectationAllServicesExecuted")
        service.execute() { error in
            let context = Record.Context.default
            context.performAndWait {
                let cdMessagesAfter = EncryptAndSendOperation.outgoingMails(
                    context: Record.Context.default, cdAccount: self.cdAccount)

                if error == nil {
                    XCTAssertEqual(cdMessagesAfter.count, 0)
                } else {
                    XCTAssertEqual(cdMessagesAfter.count, outgoingMailsToSend.count)
                }
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

    func testInitialSyncOK() {
        runServices(functionName: #function, useDisfunctionalAccount: false, expectError: false)
    }
    
    func testInitialSyncError() {
        runServices(functionName: #function, useDisfunctionalAccount: true, expectError: true)
    }
}
