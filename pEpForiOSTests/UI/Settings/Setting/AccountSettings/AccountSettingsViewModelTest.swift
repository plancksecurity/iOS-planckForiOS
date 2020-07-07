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
    var delegate : MockedAccountSettingsViewModelDelegate?
//    var actual: State?
//    var expected: State?

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

    //??
    func testUpdateToken() {

    }

    //??
    func testHandleOauth2Reauth() {
        viewModel.handleOauth2Reauth(onViewController: mockedAccountSettingsViewController)
    }

    //?
    func testHandleResetIdentity() {

    }
}

class MockedAccountSettingsViewController: UIViewController {
}

extension MockedAccountSettingsViewController: OAuthAuthorizerDelegate {
    func didAuthorize(oauth2Error: Error?, accessToken: OAuth2AccessTokenProtocol?) {

    }
}

struct State: Equatable {
    var isPEPSyncSectionShown: Bool = false
    var didCallShowErrorAlert: Bool = false
    var didCallShowLoadingView: Bool = false
    var didCallHideLoadingView: Bool = false
    var didCallUndoPEPSyncToggle: Bool = false
}

class MockedAccountSettingsViewModelDelegate : AccountSettingsViewModelDelegate {

    var showErrorAlertExpectation: XCTestExpectation?
    var showLoadingViewExpectation: XCTestExpectation?
    var hideLoadingViewExpectation: XCTestExpectation?
    var undoPEPSyncToggleExpectation: XCTestExpectation?

    init(testCase: XCTestCase, expected: State) {

        if expected.didCallShowErrorAlert {
            showErrorAlertExpectation = testCase.expectation(description: "showErrorAlert")
        }
        if expected.didCallShowLoadingView {
            showLoadingViewExpectation = testCase.expectation(description: "showLoadingView")
        }
        if expected.didCallHideLoadingView {
            hideLoadingViewExpectation = testCase.expectation(description: "hideLoadingView")
        }
        if expected.didCallUndoPEPSyncToggle {
            undoPEPSyncToggleExpectation = testCase.expectation(description: "undoPEPSyncToggle")
        }
    }

    //Changes loading view visibility
    func setLoadingView(visible: Bool) {
        if visible {
            showLoadingViewExpectation?.fulfill()
        } else {
            hideLoadingViewExpectation?.fulfill()
        }
    }
    /// Shows an alert
    func showAlert(error: Error) {
        showErrorAlertExpectation?.fulfill()
    }

    /// Undo the last Pep Sync Change
    func undoPEPSyncToggle() {
        undoPEPSyncToggleExpectation?.fulfill()
    }

}
