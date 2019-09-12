//
//  AccountSettingsViewModelTest.swift
//  pEpForiOSTests
//
//  Created by Borja González de Pablo on 22/10/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import XCTest
import PantomimeFramework
@testable import pEpForiOS
@testable import MessageModel

class AccountSettingsViewModelTest: CoreDataDrivenTestBase {

    var viewModel: AccountSettingsViewModel!
    var keySyncServiceHandshakeDelegateMoc: KeySyncServiceHandshakeDelegateMoc!

    public func testEmail() {
        setUpViewModel()

        let email = viewModel.email

        XCTAssertEqual(email, account.user.address)
    }

    public func testLoginName() {
        setUpViewModel()

        let loginName = viewModel.loginName

        XCTAssertEqual(loginName, account.imapServer?.credentials.loginName)
    }

    public func testName() {
        setUpViewModel()

        let name = viewModel.name

        XCTAssertEqual(account.user.userName, name)
    }

    public func testSmptServer() {
        setUpViewModel()

        let smptServer = viewModel.smtpServer

        XCTAssertEqual(smptServer.address, account.smtpServer?.address)
        let port =  account.smtpServer?.port
        XCTAssertNotNil(port)
        XCTAssertEqual(smptServer.port, "\(String(describing: port!))")
        XCTAssertEqual(smptServer.transport, account.smtpServer?.transport.asString())
    }

    public func testImapServer() {
        setUpViewModel()

        let imapServer = viewModel.imapServer

        XCTAssertEqual(imapServer.address, account.imapServer?.address)
        let port =  account.imapServer?.port
        XCTAssertNotNil(port)
        XCTAssertEqual(imapServer.port, "\(String(describing: port!))")
        XCTAssertEqual(imapServer.transport, account.imapServer?.transport.asString())
    }

    func testKeySyncSectionIsShown() {
        // GIVEN
        SecretTestData().createWorkingCdAccount(number: 1, context: moc)
        moc.saveAndLogErrors()

        setUpViewModel(keySyncEnabled: true)
        let expectedHeadersCount = 4
        let expectedHeader = NSLocalizedString("pEp Sync", comment: "Account settings title Key Sync")

        // WHEN
        let actualHeader = viewModel[3]
        let actualCount = viewModel.count

        //THEN
        XCTAssertEqual(expectedHeader, actualHeader)
        XCTAssertEqual(expectedHeadersCount, actualCount)
    }

    func testKeySyncSectionIsNOTShown() {
        // GIVEN
        setUpViewModel(keySyncEnabled: false)
        let expectedHeadersCount = 3
        let expectedHeaderNOTShown = NSLocalizedString("Key Sync", comment: "Account settings title Key Sync")

        // WHEN
        let actualCount = viewModel.count

        //THEN
        for i in 0..<viewModel.count {
            XCTAssertNotEqual(expectedHeaderNOTShown, viewModel[i])
        }
        XCTAssertEqual(expectedHeadersCount, actualCount)
    }

    func testKeySyncSectionIsNotShownWithOneAccount() {
        // GIVEN
        setUpViewModel(keySyncEnabled: true)
        let expectedHeadersCount = 3

        // WHEN
        let actualCount = viewModel.count

        //THEN
        XCTAssertEqual(expectedHeadersCount, actualCount)
    }

    func testUpdate() {
        let address = "localhost"
        let login = "fakelogin"
        let name = "fakeName"
        let password = "fakePassword"
        let portString = "1"
        let portInt = UInt16(portString)!

        setUpViewModel()

        let server = AccountSettingsViewModel.ServerViewModel(address: address,
                                                              port: portString,
                                                              transport: "StartTls")

        let verifyExpectation =
            expectation(description: AccountVerificationResultDelegateMock.DID_VERIFY_EXPECTATION)

        let delegate = AccountVerificationResultDelegateMock()
        delegate.expectationDidVerifyCalled = verifyExpectation
        viewModel.verifiableDelegate = delegate

        viewModel.update(loginName: login,
                         name: name,
                         password: password,
                         imap: server,
                         smtp: server)

        waitForExpectations(timeout: UnitTestUtils.asyncWaitTime)

        guard let verifier = viewModel.verifiableAccount else {
            XCTFail()
            return
        }

        XCTAssertEqual(verifier.loginName, login)
        XCTAssertEqual(verifier.password, password)
        XCTAssertEqual(verifier.serverIMAP, address)
        XCTAssertEqual(verifier.serverSMTP, address)
        XCTAssertEqual(verifier.portIMAP, portInt)
        XCTAssertEqual(verifier.portSMTP, portInt)
        XCTAssertNil(verifier.accessToken)
    }

    public func testSectionIsValid() {
        setUpViewModel()
        //Header count in AccountSettingViewModel
        let headerCount = 3
        var validSection: Bool!
        for i in 0..<headerCount {
            validSection = viewModel.sectionIsValid(section: i)
            XCTAssertTrue(validSection)
        }

        validSection = viewModel.sectionIsValid(section: headerCount)
        XCTAssertFalse(validSection)
    }

//    public func testVerified() {
//        let address = "localhost"
//        let login = "fakelogin"
//        let name = "fakeName"
//        let password = "fakePassword"
//        let portString = "1"
//
//        setUpViewModel()
//
//        let server = AccountSettingsViewModel.ServerViewModel(address: address,
//                                                              port: portString,
//                                                              transport: "StartTls")
//
//        let verifyExpectation =
//            expectation(description: AccountVerificationResultDelegateMock.DID_VERIFY_EXPECTATION)
//
//        let delegate = AccountVerificationResultDelegateMock()
//        delegate.expectationDidVerifyCalled = verifyExpectation
//        viewModel.verifiableDelegate = delegate
//
//        viewModel.update(loginName: login,
//                         name: name,
//                         password: password,
//                         imap: server,
//                         smtp: server)
//
//        viewModel.didEndVerification(result: .success(()))
//
//        waitForExpectations(timeout: UnitTestUtils.asyncWaitTime)
//    }
//
//    public func testSavePasswordAfterEndVerification() {
//        // GIVEN
//        setUpViewModel()
//        guard let imapPort = account.imapServer?.port,
//            let smtpPort = account.smtpServer?.port else {
//                XCTFail()
//                return
//        }
//        let correctPwd = account.imapServer?.credentials.password
//        let wrongPwd = "Wrong Password"
//        account.imapServer?.credentials.password = wrongPwd
//
//        let savedExpectation = expectation(description: "Did save expectation")
//        let verifiableAccount = VerifiableAccount(messageModelService: viewModel.messageModelService,
//                                                  address: account.user.address,
//                                                  userName: account.user.userName,
//                                                  loginName: account.imapServer!.credentials.loginName,
//                                                  password: correctPwd,
//                                                  serverIMAP: account.imapServer?.address,
//                                                  portIMAP: imapPort,
//                                                  transportIMAP: ConnectionTransport.init(transport: account.imapServer!.transport),
//                                                  serverSMTP: account.smtpServer?.address,
//                                                  portSMTP: smtpPort,
//                                                  transportSMTP: ConnectionTransport.init(transport: account.smtpServer!.transport),
//                                                  automaticallyTrustedImapServer: true)
//
//
//        // WHEN
//        try? verifiableAccount.save { _ in
//            savedExpectation.fulfill()
//        }
//
//        // THEN
//        waitForExpectations(timeout: UnitTestUtils.asyncWaitTime)
//        let actualPassword = account.imapServer?.credentials.password
//        XCTAssertEqual(actualPassword, correctPwd)
//    }

    private func setUpViewModel(keySyncEnabled: Bool = false) {

        keySyncServiceHandshakeDelegateMoc = KeySyncServiceHandshakeDelegateMoc()
        let theMessageModelService = MessageModelService(
            errorPropagator: ErrorPropagator(),
            keySyncServiceDelegate: keySyncServiceHandshakeDelegateMoc, keySyncEnabled: keySyncEnabled)

        viewModel = AccountSettingsViewModel(
            account: account,
            messageModelService: theMessageModelService)
    }
}

class AccountVerificationResultDelegateMock: AccountVerificationResultDelegate {
    static let DID_VERIFY_EXPECTATION = "DID_VERIFY_CALLED"
    var expectationDidVerifyCalled: XCTestExpectation?
    var error: Error? = nil

    func didVerify(result: AccountVerificationResult) {
        switch result {
        case .ok:
            self.error = nil
        case .noImapConnectData, .noSmtpConnectData:
            let theError = NSError(
                domain: #function,
                code: 777,
                userInfo: [NSLocalizedDescriptionKey: "SMTP/IMAP ERROR"])
            self.error = theError
        case .imapError(let error):
            self.error = error
        case .smtpError(let error):
            self.error = error
        }

        guard let expectation = expectationDidVerifyCalled else {
            XCTFail()
            return
        }
        expectation.fulfill()
    }
}
