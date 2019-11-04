//
//  EditableAccountSettingsViewModelTest.swift
//  pEpForiOSTests
//
//  Created by Alejandro Gelos on 04/11/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import XCTest
import PantomimeFramework
@testable import pEpForiOS
@testable import MessageModel

final class EditableAccountSettingsViewModelTest: CoreDataDrivenTestBase {

    var viewModel: EditableAccountSettingsViewModel?
    //    var keySyncServiceHandshakeDelegateMoc: KeySyncServiceHandshakeDelegateMoc?

    var actual: State?
    var expected: State?
    var expectation: XCTestExpectation?

    override func setUp() {
        super.setUp()

        viewModel = EditableAccountSettingsViewModel(account: account, messageModelService: )
        viewModel?.delegate = self
        setDefaultActualState()
    }

    override func tearDown() {
        super.tearDown()

        actual = nil
        expected = nil
        viewModel = nil
        expectation = nil
        viewModel?.delegate = nil
    }

    func testHandleSaveButton() {
        // GIVEN
//        SecretTestData().createWorkingCdAccount(number: 1, context: moc)
//
//        updateViewModelState()
//        expected = State(isPEPSyncSectionShown: true)
//
//        // WHEN
//        //no trigger, no when
//
//        //THEN
//        assertExpectations()
    }

    func testvalidateInputs() {
        // GIVEN
//        updateViewModelState()
//        expected = State(isPEPSyncSectionShown: false)
//
//        // WHEN
//        //no trigger, no when
//
//        // THEN
//        assertExpectations()
    }

    func testSucceedHandleResetIdentity() {
//        // GIVEN
//        expected = State(didCallShowLoadingView: true, didCallHideLoadingView: true)
//        expectation = expectation(description: "Call for show and hide loadingView")
//        expectation?.expectedFulfillmentCount = 2
//
//        // WHEN
//        viewModel?.handleResetIdentity()
//        waitForExpectations(timeout: TestUtil.waitTime)
//
//        // THEN
//        assertExpectations()
    }

    //MOVE!!! VERIFIABLE
    //    func testUpdate() {
    //        let address = "localhost"
    //        let login = "fakelogin"
    //        let name = "fakeName"
    //        let password = "fakePassword"
    //        let portString = "1"
    //        let portInt = UInt16(portString)!
    //
    //        let server = EditableAccountSettingsViewModel.ServerViewModel(address: address,
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
    //        waitForExpectations(timeout: UnitTestUtils.asyncWaitTime)
    //
    //        guard let verifier = viewModel.verifiableAccount else {
    //            XCTFail()
    //            return
    //        }
    //
    //        XCTAssertEqual(verifier.loginName, login)
    //        XCTAssertEqual(verifier.password, password)
    //        XCTAssertEqual(verifier.serverIMAP, address)
    //        XCTAssertEqual(verifier.serverSMTP, address)
    //        XCTAssertEqual(verifier.portIMAP, portInt)
    //        XCTAssertEqual(verifier.portSMTP, portInt)
    //        XCTAssertNil(verifier.accessToken)
    //    }

    //MOVE TO EDITABLE ACCOUNT SETT TABLE
    //    func testSectionIsValid() {
    //        //Header count in AccountSettingViewModel
    //        let headerCount = 3
    //        var validSection: Bool!
    //        for i in 0..<headerCount {
    //            validSection = viewModel.sectionIsValid(section: i)
    //            XCTAssertTrue(validSection)
    //        }
    //
    //        validSection = viewModel.sectionIsValid(section: headerCount)
    //        XCTAssertFalse(validSection)
    //    }



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















    //MOVE!!!
    //    private func setUpViewModel(keySyncEnabled: Bool = false) {
    //        keySyncServiceHandshakeDelegateMoc = KeySyncServiceHandshakeDelegateMoc()
    //        let theMessageModelService = MessageModelService(errorPropagator: ErrorPropagator(),
    //                                                         cnContactsAccessPermissionProvider: AppSettings.shared,
    //                                                         keySyncServiceDelegate: keySyncServiceHandshakeDelegateMoc,
    //                                                         keySyncEnabled: keySyncEnabled)
    //
    //        viewModel = AccountSettingsViewModel(
    //            account: account,
    //            messageModelService: theMessageModelService)
    //    }
}


// MARK: - Private

extension EditableAccountSettingsViewModelTest {
    private func setDefaultActualState() {
        actual = State()
    }

    private func assertExpectations() {
        guard let expected = expected,
            let actual = actual else {
                XCTFail()
                return
        }

        XCTAssertEqual(expected.didCallHideLoadingView, actual.didCallHideLoadingView)
        XCTAssertEqual(expected.didCallShowLoadingView, actual.didCallShowLoadingView)
        XCTAssertEqual(expected.didCallShowErrorAlert, actual.didCallShowErrorAlert)
        XCTAssertEqual(expected.didCallPopViewController, actual.didCallPopViewController)

        //In case some if missing or added but not checked
        XCTAssertEqual(expected, actual)
    }
}

//    class AccountVerificationResultDelegateMock: AccountVerificationResultDelegate {
//        static let DID_VERIFY_EXPECTATION = "DID_VERIFY_CALLED"
//        var expectationDidVerifyCalled: XCTestExpectation?
//        var error: Error? = nil
//
//        func didVerify(result: AccountVerificationResult) {
//            switch result {
//            case .ok:
//                self.error = nil
//            case .noImapConnectData, .noSmtpConnectData:
//                let theError = NSError(
//                    domain: #function,
//                    code: 777,
//                    userInfo: [NSLocalizedDescriptionKey: "SMTP/IMAP ERROR"])
//                self.error = theError
//            case .imapError(let error):
//                self.error = error
//            case .smtpError(let error):
//                self.error = error
//            }
//
//            guard let expectation = expectationDidVerifyCalled else {
//                XCTFail()
//                return
//            }
//            expectation.fulfill()
//        }
//    }


// MARK: - EditableAccountSettingsViewModelDelegate

extension EditableAccountSettingsViewModelTest: EditableAccountSettingsViewModelDelegate {
    func showErrorAlert(error: Error) {
        actual?.didCallShowErrorAlert = true
        expectation?.fulfill()
    }

    func showLoadingView() {
        actual?.didCallShowLoadingView = true
        expectation?.fulfill()
    }

    func hideLoadingView() {
        actual?.didCallHideLoadingView = true
        expectation?.fulfill()
    }

    func popViewController() {
        actual?.didCallPopViewController = true
        expectation?.fulfill()
    }
}


// MARK: - Helper Structs

extension EditableAccountSettingsViewModelTest {
    struct State: Equatable {
        var didCallShowErrorAlert: Bool = false
        var didCallShowLoadingView: Bool = false
        var didCallHideLoadingView: Bool = false
        var didCallPopViewController: Bool = false
    }

    class MessageModelServiceMock: MessageModelServiceProtocol {
        var startExpectation: XCTestExpectation

        init(startExpectation _startExpectation: XCTestExpectation) {
            startExpectation = _startExpectation
        }

        func start_old() throws {
            startExpectation.fulfill()
        }

        func processAllUserActionsAndStop_old() {
            XCTFail()
        }

        func cancel_old() {
            XCTFail()
        }

        func checkForNewMails_old(completionHandler: @escaping (Int?) -> ()) {
            XCTFail()
        }

        func enableKeySync() {
            XCTFail()
        }

        func disableKeySync() {
            XCTFail()
        }

        func start() {
            startExpectation.fulfill()
        }

        func stop() {
            XCTFail()
        }

        func finish() {
            XCTFail()
        }
    }
}
