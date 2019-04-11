//!!!: AccountVerificationService needs rewrite. See IOS-1542


////
////  AccountVerificationServiceTests.swift
////  pEpForiOS
////
////  Created by Dirk Zimmermann on 24.05.17.
////  Copyright © 2017 p≡p Security S.A. All rights reserved.
////
//
//import XCTest
//
//@testable import MessageModel
//@testable import pEpForiOS
//
//class AccountVerificationTestDelegate: AccountVerificationServiceDelegate {
//    let expVerified: XCTestExpectation?
//    var verificationResult: AccountVerificationResult?
//    var verifiedAccount: Account?
//
//    init(expVerified: XCTestExpectation? = nil) {
//        self.expVerified = expVerified
//    }
//
//    func verified(account: Account, service: AccountVerificationServiceProtocol,
//                  result: AccountVerificationResult) {
//        verifiedAccount = account
//        verificationResult = result
//        expVerified?.fulfill()
//    }
//}
//
//class AccountVerificationServiceTests: XCTestCase {
//    var persistentSetup: PersistentSetup!
//
//    override func setUp() {
//        persistentSetup = PersistentSetup()
//    }
//
//    override func tearDown() {
//        persistentSetup = nil
//    }
//
//    func testDirectlySuccess() {
//        testVerification(account: SecretTestData().createVerifiableAccount(),
//                         expectedResult: AccountVerificationResult.ok,
//                         testDirectly: true)
//    }
//
//    func testDirectlyImapFailure() {
//        testVerification(
//            account: SecretTestData().createImapTimeOutAccount(),
//            expectedResult: AccountVerificationResult.imapError(
//                .connectionTimedOut("connectionTimedOut(_:notification:)")),
//            testDirectly: true)
//    }
//
//    func testDirectlySmtpFailure() {
//        testVerification(
//            account: SecretTestData().createSmtpTimeOutAccount(),
//            expectedResult: AccountVerificationResult.smtpError(
//                .connectionTimedOut("connectionTimedOut(_:theNotification:)")),
//            testDirectly: true)
//    }
//
//    func testVerificationServiceSuccess() {
//        testVerification(account: SecretTestData().createVerifiableAccount(),
//                         expectedResult: AccountVerificationResult.ok,
//                         testDirectly: false)
//    }
//
//    func testVerificationServiceImapFailures() {
//        testVerification(
//            account: SecretTestData().createImapTimeOutAccount(),
//            expectedResult: AccountVerificationResult.imapError(
//                .connectionTimedOut("connectionTimedOut(_:notification:)")),
//            testDirectly: false)
//    }
//
//    func testVerificationServiceSmtpFailures() {
//        testVerification(
//            account: SecretTestData().createSmtpTimeOutAccount(),
//            expectedResult: AccountVerificationResult.smtpError(
//                .connectionTimedOut("connectionTimedOut(_:theNotification:)")),
//            testDirectly: false)
//    }
//
//    // MARK: HELPER
//
//    func testVerification(account: Account, expectedResult: AccountVerificationResult,
//                          testDirectly: Bool) {
//        account.save()
//
//        let expVerified = expectation(description: "account verified")
//        let delegate = AccountVerificationTestDelegate(expVerified: expVerified)
//
//        let asService = AccountVerificationService()
//        let verificationService = VerificationService(parentName: #function)
//
//        if testDirectly {
//            asService.delegate = delegate
//            asService.verify(account: account)
//        } else {
//            verificationService.requestVerification(account: account, delegate: delegate)
//        }
//
//        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
//            XCTAssertNil(error)
//            guard let result = delegate.verificationResult else {
//                XCTFail()
//                return
//            }
//            XCTAssertEqual(result, expectedResult)
//        })
//    }
//}
