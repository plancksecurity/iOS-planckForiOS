//
//  AccountVerificationServiceTests.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 24.05.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import MessageModel
@testable import pEpForiOS

class AccountVerificationTestDelegate: AccountVerificationServiceDelegate {
    let expVerified: XCTestExpectation?
    var verificationResult: AccountVerificationResult?
    var verifiedAccount: Account?

    init(expVerified: XCTestExpectation? = nil) {
        self.expVerified = expVerified
    }

    func verified(account: Account, service: AccountVerificationServiceProtocol,
                  result: AccountVerificationResult) {
        verifiedAccount = account
        verificationResult = result
        expVerified?.fulfill()
    }
}

class AccountVerificationServiceTests: XCTestCase {
    var persistentSetup: PersistentSetup!

    override func setUp() {
        persistentSetup = PersistentSetup()
    }
    
    override func tearDown() {
        persistentSetup = nil
    }

    func testVerification(account: Account, expectedResult: AccountVerificationResult,
                          testDirectly: Bool) {
        let expVerified = expectation(description: "account verified")
        let delegate = AccountVerificationTestDelegate(expVerified: expVerified)

        let asService = AccountVerificationService()
        let msService = MessageSyncService()

        if testDirectly {
            asService.delegate = delegate
            asService.verify(account: account)
        } else {
            msService.requestVerification(account: account, delegate: delegate)
        }

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            guard let result = delegate.verificationResult else {
                XCTFail()
                return
            }
            XCTAssertEqual(result, expectedResult)
        })
    }

    func testDirectlySuccess() {
        testVerification(account: TestData().createWorkingAccount(),
                         expectedResult: AccountVerificationResult.ok,
                         testDirectly: true)
    }

    func testDirectlyFailures() {
        testVerification(
            account: TestData().createImapTimeOutAccount(),
            expectedResult: AccountVerificationResult.imapError(
                .connectionTimedOut("connectionTimedOut(_:notification:)")),
            testDirectly: true)
        testVerification(
            account: TestData().createSmtpTimeOutAccount(),
            expectedResult: AccountVerificationResult.smtpError(
                .connectionTimedOut("connectionTimedOut(_:theNotification:)")),
            testDirectly: true)
    }

    func testMessageSyncServiceSuccess() {
        testVerification(account: TestData().createWorkingAccount(),
                         expectedResult: AccountVerificationResult.ok,
                         testDirectly: false)
    }

    func testMessageSyncServiceFailures() {
        testVerification(
            account: TestData().createImapTimeOutAccount(),
            expectedResult: AccountVerificationResult.imapError(
                .connectionTimedOut("connectionTimedOut(_:notification:)")),
            testDirectly: false)
        testVerification(
            account: TestData().createSmtpTimeOutAccount(),
            expectedResult: AccountVerificationResult.smtpError(
                .connectionTimedOut("connectionTimedOut(_:theNotification:)")),
            testDirectly: false)
    }
}
