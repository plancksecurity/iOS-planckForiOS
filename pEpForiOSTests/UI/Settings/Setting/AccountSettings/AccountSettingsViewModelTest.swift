//
//  AccountSettingsViewModelTest.swift
//  pEpForiOSTests
//
//  Created by Alejandro Gelos on 04/11/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import XCTest
import PantomimeFramework
@testable import pEpForiOS
@testable import MessageModel

final class AccountSettingsViewModelTest: CoreDataDrivenTestBase {

    var viewModel: AccountSettingsViewModel?

    var actual: State?
    var expected: State?
    var expectations: TestExpectations?

    override func setUp() {
        super.setUp()

        viewModel = AccountSettingsViewModel(account: account)
        viewModel?.delegate = self
        setDefaultActualState()
    }

    override func tearDown() {
        super.tearDown()

        actual = nil
        expected = nil
        viewModel = nil
        expectations = nil
        viewModel?.delegate = nil
    }

    func testPEPSyncSectionIsShown() {
        // GIVEN
        SecretTestData().createWorkingCdAccount(number: 1, context: moc)

        updateViewModelState()
        expected = State(isPEPSyncSectionShown: true)

        // WHEN
        //no trigger, no when

        //THEN
        assertExpectations()
    }

    func testPEPSyncSectionIsNOTShown() {
        // GIVEN
        updateViewModelState()
        expected = State(isPEPSyncSectionShown: false)

        // WHEN
        //no trigger, no when

        // THEN
        assertExpectations()
    }

    func testSucceedHandleResetIdentity() {
        // GIVEN
        expected = State(didCallShowLoadingView: true, didCallHideLoadingView: true)
        expectations = TestExpectations(testCase: self, expected: expected)

        // WHEN
        viewModel?.handleResetIdentity()
        waitForExpectations(timeout: TestUtil.waitTime)

        // THEN
        assertExpectations()
    }

    func testpEpSyncEnableSucceed() {
        // GIVEN
        expected = State()

        // WHEN
        viewModel?.pEpSync(enable: true)//!!!: IOS-2325_!

        // THEN
        assertExpectations()
    }

    func testpEpSyncDisableSucceed() {
        // GIVEN
        expected = State()

        // WHEN
        viewModel?.pEpSync(enable: false)//!!!: IOS-2325_!

        // THEN
        assertExpectations()
    }
}

// MARK: - Private

extension AccountSettingsViewModelTest {
    private func setDefaultActualState() {
        actual = State()
    }

    private func updateViewModelState() {
        guard let viewModel = viewModel else {
            XCTFail()
            return
        }
        let pEpSyncHeader = NSLocalizedString("pEp Sync", comment: "Account settings title pEp Sync")

        for i in 0..<viewModel.count {
            guard viewModel[i] == pEpSyncHeader else { continue }
            actual?.isPEPSyncSectionShown = true
        }
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
        XCTAssertEqual(expected.didCallUndoPEPSyncToggle, actual.didCallUndoPEPSyncToggle)
        XCTAssertEqual(expected.isPEPSyncSectionShown, actual.isPEPSyncSectionShown)

        //In case some if missing or added but not checked
        XCTAssertEqual(expected, actual)
    }
}

// MARK: - AccountSettingsViewModelDelegate

extension AccountSettingsViewModelTest: AccountSettingsViewModelDelegate {
    func showErrorAlert(error: Error) {
        actual?.didCallShowErrorAlert = true
        expectations?.showErrorAlertExpectation?.fulfill()
    }

    func undoPEPSyncToggle() {
        actual?.didCallUndoPEPSyncToggle = true
        expectations?.undoPEPSyncToggleExpectation?.fulfill()
    }

    func showLoadingView() {
        actual?.didCallShowLoadingView = true
        expectations?.showLoadingViewExpectation?.fulfill()
    }

    func hideLoadingView() {
        actual?.didCallHideLoadingView = true
        expectations?.hideLoadingViewExpectation?.fulfill()
    }
}

// MARK: - Helping Structures

extension AccountSettingsViewModelTest {
    struct State: Equatable {
        var isPEPSyncSectionShown: Bool = false
        var didCallShowErrorAlert: Bool = false
        var didCallShowLoadingView: Bool = false
        var didCallHideLoadingView: Bool = false
        var didCallUndoPEPSyncToggle: Bool = false
    }

    final class TestExpectations {
        var showErrorAlertExpectation: XCTestExpectation?
        var showLoadingViewExpectation: XCTestExpectation?
        var hideLoadingViewExpectation: XCTestExpectation?
        var undoPEPSyncToggleExpectation: XCTestExpectation?

        init(testCase: XCTestCase, expected: State?) {
            if expected?.didCallShowErrorAlert == true {
                showErrorAlertExpectation = testCase.expectation(description: "showErrorAlert")
            }
            if expected?.didCallShowLoadingView == true {
                showLoadingViewExpectation = testCase.expectation(description: "showLoadingView")
            }
            if expected?.didCallHideLoadingView == true {
                hideLoadingViewExpectation = testCase.expectation(description: "hideLoadingView")
            }
            if expected?.didCallUndoPEPSyncToggle == true {
                undoPEPSyncToggleExpectation = testCase.expectation(description: "undoPEPSyncToggle")
            }
        }
    }
}
