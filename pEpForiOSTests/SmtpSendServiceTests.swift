//
//  SmtpSendServiceTests.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 29.06.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import MessageModel
@testable import pEpForiOS

class TestSmtpSendServiceDelegate: SmtpSendServiceDelegate {
    var successfullySentMessageIDs = [MessageID]()

    func sent(messageIDs: [MessageID]) {
        successfullySentMessageIDs = messageIDs
    }
}

class SmtpSendServiceTests: XCTestCase {
    var persistentSetup: PersistentSetup!

    var cdAccount: CdAccount!
    var cdAccountDisfunctional: CdAccount!

    override func setUp() {
        super.setUp()
        persistentSetup = PersistentSetup()

        let cdAccount = TestData().createWorkingCdAccount()
        TestUtil.skipValidation()
        Record.saveAndWait()
        self.cdAccount = cdAccount

        let cdDisfunctionalAccount = TestData().createDisfunctionalCdAccount()
        TestUtil.skipValidation()
        Record.saveAndWait()
        self.cdAccountDisfunctional = cdDisfunctionalAccount
    }

    func syncData(cdAccount: CdAccount) -> (ImapSyncData, SmtpSendData)? {
        guard
            let imapCI = cdAccount.imapConnectInfo,
            let smtpCI = cdAccount.smtpConnectInfo else {
                XCTFail()
                return nil
        }
        return (ImapSyncData(connectInfo: imapCI), SmtpSendData(connectInfo: smtpCI))
    }

    func runSmtpSendService(shouldSucceed: Bool, verifyError: @escaping ServiceFinishedHandler) {
        guard let theCdAccount = cdAccount else {
            XCTFail()
            return
        }

        let outgoingMailsToSend = TestUtil.createOutgoingMails(
            cdAccount: theCdAccount, testCase: self, numberOfMails: 3)
        XCTAssertGreaterThan(outgoingMailsToSend.count, 0)

        if !shouldSucceed {
            TestUtil.makeServersUnreachable(cdAccount: theCdAccount)
        }

        guard let (imapSyncData, smtpSendData) = TestUtil.syncData(cdAccount: theCdAccount) else {
            XCTFail()
            return
        }

        let expBackgroundTaskFinishedAtLeastOnce = expectation(
            description: "expectationBackgrounded")
        let backgrounder = MockBackgrounder(
            expBackgroundTaskFinishedAtLeastOnce: expBackgroundTaskFinishedAtLeastOnce)

        let smtpSentDelegate = TestSmtpSendServiceDelegate()
        let smtpService = SmtpSendService(
            parentName: #function, backgrounder: backgrounder,
            imapSyncData: imapSyncData, smtpSendData: smtpSendData)
        smtpService.delegate = smtpSentDelegate
        let expectationSmtpExecuted = expectation(description: "expectationSmtpExecuted")
        smtpService.execute() { error in
            if error == nil {
                XCTAssertEqual(smtpSentDelegate.successfullySentMessageIDs.count,
                               outgoingMailsToSend.count)
            } else {
                XCTAssertLessThan(smtpSentDelegate.successfullySentMessageIDs.count,
                                  outgoingMailsToSend.count)
            }
            verifyError(error)
            expectationSmtpExecuted.fulfill()
        }
        waitForExpectations(timeout: TestUtil.waitTime) { error in
            XCTAssertNil(error)
        }
    }

    func testSmtpSendServiceOk() {
        runSmtpSendService(shouldSucceed: true) { error in
            XCTAssertNil(error)
        }
    }

    func testSmtpSendServiceError() {
        runSmtpSendService(shouldSucceed: false) { error in
            XCTAssertNotNil(error)
        }
    }
}
