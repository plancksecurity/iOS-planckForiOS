//
//  AccountSettingsViewModelTest.swift
//  pEpForiOSTests
//
//  Created by Borja González de Pablo on 22/10/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import XCTest
@testable import pEpForiOS
@testable import MessageModel // Uses AccountVerificationService.

class AccountSettingsViewModelTest: CoreDataDrivenTestBase {

    var viewModel: AccountSettingsViewModel!

    public func testEmail() {
        setUpViewModel()

        let email = viewModel.email

        XCTAssertEqual(email, account.user.address)
    }

    public func testLoginName() {
        setUpViewModel()

        let loginName = viewModel.loginName

        XCTAssertEqual(loginName, account.server(with: .imap)?.credentials.loginName)
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
        XCTAssertEqual(smptServer.transport, account.smtpServer?.transport?.asString())
    }

    public func testImapServer() {
        setUpViewModel()

        let imapServer = viewModel.imapServer

        XCTAssertEqual(imapServer.address, account.imapServer?.address)
        let port =  account.imapServer?.port
        XCTAssertNotNil(port)
        XCTAssertEqual(imapServer.port, "\(String(describing: port!))")
        XCTAssertEqual(imapServer.transport, account.imapServer?.transport?.asString())
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
        viewModel.delegate = delegate

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

    public func testVerified() {
        setUpViewModel()

        let verifyExpectation =
            expectation(description: AccountVerificationResultDelegateMock.DID_VERIFY_EXPECTATION)

        let delegate = AccountVerificationResultDelegateMock()
        delegate.expectationDidVerifyCalled = verifyExpectation
        viewModel.delegate = delegate

        viewModel.didEndVerification(result: .success(()))

        waitForExpectations(timeout: UnitTestUtils.waitTime)
    }


    private func setUpViewModel() {
        account.save()
        viewModel = AccountSettingsViewModel(account: account)
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
