//IOS-2241 DOES NOT COMPILE
////
////  VerifiableAccountTest.swift
////  pEpForiOSTests
////
////  Created by Dirk Zimmermann on 16.04.19.
////  Copyright © 2019 p≡p Security S.A. All rights reserved.
////
//
//import XCTest
//@testable import MessageModel
//import PEPObjCAdapterFramework
//import PantomimeFramework
//
//class VerifiableAccountTest: PersistentStoreDrivenTestBase {
//
//    var account1 : Account?
//    var account2 : Account?
//
//    override func setUp() {
//        super.setUp()
//        account1 = SecretTestData().createWorkingAccount()
//        account2 = SecretTestData().createWorkingAccount(number: 1)
//    }
//
////    func testBasicSuccess() {
////        let theMessageModelService = MessageModelService(
////            errorPropagator: ErrorPropagator(),
////            notifyHandShakeDelegate: MockNotifyHandshakeDelegate())
////        let verifier = VerifiableAccount(messageModelService: theMessageModelService)
////
////        var verifierType: VerifiableAccountProtocol = verifier
////        SecretTestData().populateVerifiableAccount(
////            verifiableAccount: &verifierType)
////        let expDidVerify = expectation(description: "expDidVerify")
////        let delegate = VerifiableAccountTestDelegate(expDidVerify: expDidVerify)
////        try! check(verifier: &verifierType, delegate: delegate)
////        wait(for: [expDidVerify], timeout: TestUtil.waitTime)
////
////        guard let theResult = delegate.result else {
////            XCTFail()
////            return
////        }
////        switch theResult {
////        case .success(()):
////            break
////        case .failure(_):
////            XCTFail()
////        }
////    }
////
////    func testFailingValidation() {
////        let (exceptionOnVerify, exceptionOnSave) = checkFailingValidation() {
////            var newOne = $0
////            newOne.address = nil
////            return newOne
////        }
////        XCTAssertTrue(exceptionOnVerify)
////        XCTAssertTrue(exceptionOnSave)
////    }
////
////    func testBasicFailingVerification() {
////        let result = checkBasicVerification() { v in
////            var verifiable = v
////
////            // This should make it fail quickly
////            verifiable.serverIMAP = "localhost"
////            verifiable.portIMAP = 5
////            verifiable.serverSMTP = "localhost"
////            verifiable.portSMTP = 5
////
////            return verifiable
////        }
////        switch result {
////        case .success(_):
////            XCTFail()
////        case .failure(_):
////            break
////        }
////    }
////
////    func testBasicFailingVerificationWithWrongPassword() {
////        let result = checkBasicVerification() { v in
////            var verifiable = v
////
////            verifiable.password = "xxxxxxxxxx"
////
////            return verifiable
////        }
////        switch result {
////        case .success(_):
////            XCTFail()
////        case .failure(_):
////            break
////        }
////    }
////
////    // MARK: Helpers
////
////    /// Tries `verify()` and `save()` on the given `VerifiableAccountProtocol`.
////    /// - Returns: A tuple of Bool denoting if `verify()` and `save()` threw exceptions.
////    func checkFailingValidation(
////        modifier: (VerifiableAccountProtocol) -> VerifiableAccountProtocol) -> (Bool, Bool) {
////        let theMessageModelService = MessageModelService(
////            errorPropagator: ErrorPropagator(),
////            notifyHandShakeDelegate: MockNotifyHandshakeDelegate())
////        let verifier = VerifiableAccount(messageModelService: theMessageModelService)
////
////        var verifierType: VerifiableAccountProtocol = verifier
////        SecretTestData().populateVerifiableAccount(
////            verifiableAccount: &verifierType)
////
////        // Invalidate it
////        var verifierToBeUsed = modifier(verifierType)
////
////        var exceptionHit1 = false
////        do {
////            try check(verifier: &verifierToBeUsed, delegate: nil)
////        } catch {
////            exceptionHit1 = true
////        }
////
////        var exceptionHit2 = false
////        do {
////            try check(verifier: &verifierToBeUsed, delegate: nil)
////        } catch {
////            exceptionHit2 = true
////        }
////
////        return (exceptionHit1, exceptionHit2)
////    }
////
////    func check(verifier: inout VerifiableAccountProtocol,
////               delegate: VerifiableAccountDelegate?) throws {
////        verifier.verifiableAccountDelegate = delegate
////        try verifier.verify()
////    }
////
////    enum TestError: Error {
////        case noResult
////    }
////
////    /// Expects a failure, lets caller modify the `VerifiableAccountProtocol`.
////    func checkBasicVerification(
////        modifier: (VerifiableAccountProtocol) -> VerifiableAccountProtocol)
////        -> Result<Void, Error> {
////            let theMessageModelService = MessageModelService(
////                errorPropagator: ErrorPropagator(),
////                notifyHandShakeDelegate: MockNotifyHandshakeDelegate())
////            let verifier = VerifiableAccount(messageModelService: theMessageModelService)
////
////            var verifiable: VerifiableAccountProtocol = verifier
////            SecretTestData().populateVerifiableAccount(
////                verifiableAccount: &verifiable)
////
////            verifiable = modifier(verifiable)
////
////            let expDidVerify = expectation(description: "expDidVerify")
////            let delegate = VerifiableAccountTestDelegate(expDidVerify: expDidVerify)
////            try! check(verifier: &verifiable, delegate: delegate)
////            wait(for: [expDidVerify], timeout: TestUtil.waitTime)
////
////            guard let result = delegate.result else {
////                XCTFail()
////                return .failure(TestError.noResult)
////            }
////
////            return result
////    }
////}
////
////class VerifiableAccountTestDelegate: VerifiableAccountDelegate {
////    var result: Result<Void, Error>?
////
////    let expDidVerify: XCTestExpectation
////
////    init(expDidVerify: XCTestExpectation) {
////        self.expDidVerify = expDidVerify
////    }
////
////    func didEndVerification(result: Result<Void, Error>) {
////        self.result = result
////        expDidVerify.fulfill()
////    }
//}
//
//extension VerifiableAccountTest {
//
//    private func getVerificableAccount() -> VerifiableAccount{
//        let verifiableAccount = VerifiableAccount()
//
//        guard let acc = account1 else {
//            XCTFail()
//            return verifiableAccount
//        }
//
//        verifiableAccount.address =  acc.user.address
//        verifiableAccount.userName = acc.user.address
//        verifiableAccount.loginNameIMAP = account1!.imapServer?.credentials.loginName
//        verifiableAccount.loginNameSMTP = account1!.smtpServer?.credentials.loginName
//        // Note: auth method is never taken from LAS. We either have OAuth2,
//        // as determined previously, or we will defer to pantomime to find out the best method.
//        verifiableAccount.authMethod = nil
//        verifiableAccount.password = acc.imapServer?.credentials.password
//        verifiableAccount.accessToken = nil
//        verifiableAccount.serverIMAP = acc.imapServer?.address
//        verifiableAccount.portIMAP = (acc.imapServer?.port)!
//        verifiableAccount.transportIMAP = ConnectionTransport(transport: acc.imapServer!.transport)
//        verifiableAccount.serverSMTP = acc.smtpServer?.address
//        verifiableAccount.portSMTP = (acc.smtpServer?.port)!
//        verifiableAccount.transportSMTP = ConnectionTransport(transport: acc.smtpServer!.transport)
//        verifiableAccount.isAutomaticallyTrustedImapServer = false
//        return verifiableAccount
//    }
//
//    private func deleteAllAccounts() {
//        let accs = CdAccount.all(in: moc)
//        accs?.forEach({ (account) in
//            moc.delete(account)
//        })
//        moc.saveAndLogErrors()
//    }
//
//    class MessageModelServiceMock: MessageModelServiceProtocol {
//        var startExpectation: XCTestExpectation
//
//        init(startExpectation _startExpectation: XCTestExpectation) {
//            startExpectation = _startExpectation
//        }
//
//        func start_old() throws {
//            startExpectation.fulfill()
//        }
//
//        func processAllUserActionsAndStop_old() {
//            XCTFail()
//        }
//
//        func cancel_old() {
//            XCTFail()
//        }
//
//        func checkForNewMails_old(completionHandler: @escaping (Int?) -> ()) {
//            XCTFail()
//        }
//
//        func enableKeySync() {
//            XCTFail()
//        }
//
//        func disableKeySync() {
//            XCTFail()
//        }
//
//        func start() {
//            startExpectation.fulfill()
//        }
//
//        func stop() {
//            XCTFail()
//        }
//
//        func finish() {
//            XCTFail()
//        }
//    }
//}
//
//
//
//
