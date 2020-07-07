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

    func testUpdateToken() {
        //TODO: test this when the method is properly implemented.
    }

    //??
    func testHandleOauth2Reauth() {

    }

    func testHandleResetIdentity() {
        let showLoadingViewExpectation = expectation(description: "showLoadingViewExpectation")
        let delegate = MockedAccountSettingsViewModelDelegate(testCase: self,
                                                              showLoadingViewExpectation: showLoadingViewExpectation)
        viewModel = AccountSettingsViewModel(account: account, delegate: delegate)
        viewModel.handleResetIdentity()
        waitForExpectations(timeout: TestUtil.waitTime)
    }
}

class MockedAccountSettingsViewController: UIViewController {
}

extension MockedAccountSettingsViewController: OAuthAuthorizerDelegate {
    func didAuthorize(oauth2Error: Error?, accessToken: OAuth2AccessTokenProtocol?) {

    }
}

class MockedAccountSettingsViewModelDelegate : AccountSettingsViewModelDelegate {

//    var showErrorAlertExpectation: XCTestExpectation?
    var showLoadingViewExpectation: XCTestExpectation?
//    var hideLoadingViewExpectation: XCTestExpectation?
//    var undoPEPSyncToggleExpectation: XCTestExpectation?

    init(testCase: XCTestCase,
//         showErrorAlertExpectation: XCTestExpectation? = nil,
         showLoadingViewExpectation: XCTestExpectation? = nil
//         hideLoadingViewExpectation: XCTestExpectation? = nil,
//         undoPEPSyncToggleExpectation: XCTestExpectation? = nil
    ) {

//        self.showErrorAlertExpectation = showErrorAlertExpectation
        self.showLoadingViewExpectation = showLoadingViewExpectation
//        self.hideLoadingViewExpectation = hideLoadingViewExpectation
//        self.undoPEPSyncToggleExpectation = undoPEPSyncToggleExpectation
    }

    func setLoadingView(visible: Bool) {
        if visible {
            if showLoadingViewExpectation != nil {
                showLoadingViewExpectation?.fulfill()
                showLoadingViewExpectation = nil
            }
        } else {
//            if hideLoadingViewExpectation != nil {
//                hideLoadingViewExpectation?.fulfill()
//                hideLoadingViewExpectation = nil
//            }
        }
    }

    func showAlert(error: Error) {
//        showErrorAlertExpectation?.fulfill()
    }

    func undoPEPSyncToggle() {
//        undoPEPSyncToggleExpectation?.fulfill()
    }
}
