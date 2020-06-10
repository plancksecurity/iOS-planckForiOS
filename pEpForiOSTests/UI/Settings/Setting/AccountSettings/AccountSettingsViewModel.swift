//
//  AccountSettingsViewModel2.swift
//  pEpForiOSTests
//
//  Created by Martin Brude on 20/05/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import XCTest
import Foundation

@testable import pEpForiOS
@testable import MessageModel

class AccountSettingsViewModel2Test: AccountDrivenTestBase {

    var viewModel : AccountSettingsViewModel!
    var delegate : MockedAccountSettingsViewModelDelegate?
    var actual: State?
    var expected: State?

    //Number of sections corresponding to AccountSettingsViewModel's Section Types
    let numberOfSections = 3

    override func setUp() {
        super.setUp()
        //let clientCertificateUtil = ClientCertificateUtilMockTest()
        viewModel = AccountSettingsViewModel(account: account)
    }

    func testNumberOfSections() throws {
        XCTAssertEqual(viewModel.sections.count, numberOfSections)
    }

    // MARK: - Actions

    //Fails
    func testHandleResetIdentity() {
        let state = State(didCallShowLoadingView: true, didCallHideLoadingView: true)
        let delegate = MockedAccountSettingsViewModelDelegate(testCase: self, expected: state)
        viewModel = AccountSettingsViewModel(account: account, delegate: delegate)
        viewModel.handleResetIdentity()
    }

    func testPepSync() {
        var boolValue = true
        viewModel.pEpSync(enable: boolValue)
        XCTAssertEqual(viewModel.pEpSync, boolValue)

        boolValue = false
        viewModel.pEpSync(enable: boolValue)
        XCTAssertEqual(viewModel.pEpSync, boolValue)
    }

    // MARK: - Client Certificate

    func testHasCertificate() {
        XCTAssertEqual(viewModel.hasCertificate(), false)
    }

    func testCertificateInfo() {
        XCTAssertNotNil(viewModel.certificateInfo())
    }

    func testClientCertificateViewModel() {
        XCTAssertNotNil(viewModel.clientCertificateViewModel())
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

    func showErrorAlert(error: Error) {
        showErrorAlertExpectation?.fulfill()
    }

    func undoPEPSyncToggle() {
        undoPEPSyncToggleExpectation?.fulfill()
    }

    func showLoadingView() {
        showLoadingViewExpectation?.fulfill()
    }

    func hideLoadingView() {
        hideLoadingViewExpectation?.fulfill()
    }
}
