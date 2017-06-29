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

class SmtpSendServiceTests: XCTestCase {
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

        let cdDisfunctionalAccount = TestData().createDisfunctionalCdAccount()
        cdDisfunctionalAccount.identity?.isMySelf = true
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

    func runSmtpSendService(
        cdAccount theCdAccount: CdAccount, verifyError: @escaping (_ error: Error?) -> ()) {
        guard let (imapSyncData, smtpSendData) = TestUtil.syncData(cdAccount: theCdAccount) else {
            XCTFail()
            return
        }

        let numberOfMailsToSend = TestUtil.createOutgoingMails(cdAccount: theCdAccount)

        let expectationBackgrounded = expectation(description: "expectationBackgrounded")
        let backgrounder = MockBackgrounder(expBackgrounded: expectationBackgrounded)

        let smtpService = SmtpSendService(parentName: #function, backgrounder: backgrounder)
        let expectationSmtpExecuted = expectation(description: "expectationSmtpExecuted")
        smtpService.execute(
        smtpSendData: smtpSendData, imapSyncData: imapSyncData) { error in
            if error == nil {
                XCTAssertEqual(smtpService.successfullySentMessageIDs.count, numberOfMailsToSend)
            } else {
                XCTAssertLessThan(smtpService.successfullySentMessageIDs.count, numberOfMailsToSend)
            }
            verifyError(error)
            expectationSmtpExecuted.fulfill()
        }
        waitForExpectations(timeout: TestUtil.waitTime) { error in
            XCTAssertNil(error)
        }
    }

    func testSmtpSendServiceOk() {
        runSmtpSendService(cdAccount: cdAccount) { error in
            XCTAssertNil(error)
        }
    }

    func testSmtpSendServiceError() {
        runSmtpSendService(cdAccount: cdAccountDisfunctional) { error in
            XCTAssertNotNil(error)
        }
    }
}
