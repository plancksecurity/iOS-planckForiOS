//
//  AccountSettingsViewModelTest.swift
//  pEpForiOSTests
//
//  Created by Martin Brude on 07/07/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import pEpForiOS
@testable import MessageModel

class AccountSettingsViewModelTest: AccountDrivenTestBase {

    var mockedAccountSettingsViewController = MockedAccountSettingsViewController()
    var viewModel : AccountSettingsViewModel!

    //Number of sections corresponding to AccountSettingsViewModel's Section Types
    var dummySections : [AccountSettingsViewModel.Section] = [AccountSettingsViewModel.Section]()

    override func setUp() {
        super.setUp()

        let dummyAccountSection = AccountSettingsViewModel.Section(title: "My account", rows:[] , type: .account)
        let dummyImapSection = AccountSettingsViewModel.Section(title: "Imap", rows:[] , type: .imap)
        let dummySmtpSection = AccountSettingsViewModel.Section(title: "Smtp", rows:[] , type: .smtp)

        dummySections.append(dummyAccountSection)
        dummySections.append(dummyImapSection)
        dummySections.append(dummySmtpSection)

        viewModel = AccountSettingsViewModel(account: account)
    }

    func testNumberOfSections() throws {
        XCTAssertEqual(viewModel.sections.count, dummySections.count)
    }

    func testPEpSync() {
        var boolValue = true
        viewModel.pEpSync(enable: boolValue)
        XCTAssertEqual(viewModel.pEpSync, boolValue)

        boolValue = false
        viewModel.pEpSync(enable: boolValue)
        XCTAssertEqual(viewModel.pEpSync, boolValue)
    }

    func testHandleResetIdentity() {
        let showLoadingViewExpectation = expectation(description: "showLoadingViewExpectation")
        let hideLoadingViewExpectation = expectation(description: "hideLoadingViewExpectation")

        let delegate = MockedAccountSettingsViewModelDelegate(testCase: self,
                                                              showLoadingViewExpectation: showLoadingViewExpectation,
                                                              hideLoadingViewExpectation: hideLoadingViewExpectation)
        viewModel = AccountSettingsViewModel(account: account, delegate: delegate)
        viewModel.handleResetIdentity()
        waitForExpectations(timeout: TestUtil.waitTime)
    }

    func testShowAlert() {
        let showErrorAlertExpectation = expectation(description: "showErrorAlertExpectation")
        let delegate = MockedAccountSettingsViewModelDelegate(testCase: self,
                                                              showErrorAlertExpectation: showErrorAlertExpectation)
        delegate.showAlert(error: NSError())
        waitForExpectations(timeout: TestUtil.waitTime)
    }

    func testUndoPEPSyncToggle() {
        let undoPEPSyncToggleExpectation = expectation(description: "undoPEPSyncToggle")
        let delegate = MockedAccountSettingsViewModelDelegate(testCase: self,
                                                              undoPEPSyncToggleExpectation: undoPEPSyncToggleExpectation)

        viewModel = AccountSettingsViewModel(account: account, delegate: delegate)

        viewModel.pEpSync(enable: true)
        delegate.undoPEPSyncToggle()
        waitForExpectations(timeout: TestUtil.waitTime)
    }

    func testHandleOauth2Reauth() {
        let td = TestData()
        let account = td.createVerifiableAccountSettings().account()
        let mockedAccountSettingsViewController = MockedAccountSettingsViewController()
        viewModel = AccountSettingsViewModel(account: account)
        viewModel.handleOauth2Reauth(onViewController: mockedAccountSettingsViewController)
        XCTAssertTrue(true, "handleOauth2Reauth did not crash")
    }
}

class MockedAccountSettingsViewController: UIViewController {
}

extension MockedAccountSettingsViewController: OAuthAuthorizerDelegate {
    func didAuthorize(oauth2Error: Error?, accessToken: OAuth2AccessTokenProtocol?) {
    }
}

class MockedAccountSettingsViewModelDelegate : AccountSettingsViewModelDelegate {

    var showErrorAlertExpectation: XCTestExpectation?
    var showLoadingViewExpectation: XCTestExpectation?
    var hideLoadingViewExpectation: XCTestExpectation?
    var undoPEPSyncToggleExpectation: XCTestExpectation?

    init(testCase: XCTestCase,
         showErrorAlertExpectation: XCTestExpectation? = nil,
         showLoadingViewExpectation: XCTestExpectation? = nil,
         hideLoadingViewExpectation: XCTestExpectation? = nil,
         undoPEPSyncToggleExpectation: XCTestExpectation? = nil) {
        self.showErrorAlertExpectation = showErrorAlertExpectation
        self.showLoadingViewExpectation = showLoadingViewExpectation
        self.hideLoadingViewExpectation = hideLoadingViewExpectation
        self.undoPEPSyncToggleExpectation = undoPEPSyncToggleExpectation
    }

    func setLoadingView(visible: Bool) {
        if visible {
            if showLoadingViewExpectation != nil {
                showLoadingViewExpectation?.fulfill()
                showLoadingViewExpectation = nil
            }
        } else {
            if hideLoadingViewExpectation != nil {
                hideLoadingViewExpectation?.fulfill()
                hideLoadingViewExpectation = nil
            }
        }
    }

    func showAlert(error: Error) {
        if showErrorAlertExpectation != nil {
            showErrorAlertExpectation?.fulfill()
            showErrorAlertExpectation = nil
        }
    }

    func undoPEPSyncToggle() {
        if undoPEPSyncToggleExpectation != nil {
            undoPEPSyncToggleExpectation?.fulfill()
            undoPEPSyncToggleExpectation = nil
        }
    }
}
