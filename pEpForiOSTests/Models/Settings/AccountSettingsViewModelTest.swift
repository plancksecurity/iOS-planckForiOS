//
//  AccountSettingsViewModelTest.swift
//  pEpForiOSTests
//
//  Created by Borja González de Pablo on 22/10/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import XCTest
@testable import pEpForiOS
@testable import MessageModel

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
        setUpViewModel()
        let server = AccountSettingsViewModel.ServerViewModel(address: "fakeAddress",
                                                              port: "123",
                                                              transport: "StartTls")


        viewModel.update(loginName: "fakelogin",
                         name: "fakeName",
                         password: "fakePassword",
                         imap: server,
                         smtp: server)

        XCTAssertEqual(viewModel.account.smtpServer?.credentials.loginName, "fakelogin")
        XCTAssertEqual(viewModel.account.smtpServer?.credentials.password, "fakePassword")
        XCTAssertEqual(viewModel.account.imapServer?.credentials.loginName, "fakelogin")
        XCTAssertEqual(viewModel.account.imapServer?.credentials.password, "fakePassword")

        XCTAssertEqual(viewModel.account.imapServer?.address, "fakeAddress")
        XCTAssertEqual(viewModel.account.imapServer?.port, 123)
        XCTAssertEqual(viewModel.account.imapServer?.transport, .startTls)

        XCTAssertEqual(viewModel.account.smtpServer?.address, "fakeAddress")
        XCTAssertEqual(viewModel.account.smtpServer?.port, 123)
        XCTAssertEqual(viewModel.account.smtpServer?.transport, .startTls)

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

        viewModel.verified(account: account,
                           service: AccountVerificationService(),
                           result: .ok)

        waitForExpectations(timeout: UnitTestUtils.waitTime)
    }


    private func setUpViewModel(){
        viewModel = AccountSettingsViewModel(account: account)
        viewModel.messageSyncService = MessageSyncService()
    }
}

class AccountVerificationResultDelegateMock: AccountVerificationResultDelegate {
    static let DID_VERIFY_EXPECTATION = "DID_VERIFY_CALLED"
    var expectationDidVerifyCalled: XCTestExpectation?

    func didVerify(result: AccountVerificationResult, accountInput: AccountUserInput?) {
        guard let expectation = expectationDidVerifyCalled else {
            XCTFail()
            return
        }
        expectation.fulfill()
    }


}


