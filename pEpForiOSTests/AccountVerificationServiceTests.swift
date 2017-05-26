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

class AccountVerificationDelegate: AccountVerificationServiceDelegate {
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

    func testVerification(account: Account, expectedResult: AccountVerificationResult) {
        let expVerified = expectation(description: "account verified")
        let delegate = AccountVerificationDelegate(expVerified: expVerified)
        let service = AccountVerificationService()
        service.delegate = delegate
        service.verify(account: account)

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            guard let result = delegate.verificationResult else {
                XCTFail()
                return
            }
            XCTAssertEqual(result, expectedResult)
        })
    }

    func testSuccess() {
        testVerification(account: TestData().createWorkingAccount(),
                         expectedResult: AccountVerificationResult.ok)
    }

    func testFailures() {
        testVerification(account: TestData().createImapTimeOutAccount(),
                         expectedResult: AccountVerificationResult.error(.networkError))
        testVerification(account: TestData().createSmtpTimeOutAccount(),
                         expectedResult: AccountVerificationResult.error(.networkError))
    }
}
