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

final class EditableAccountSettingsViewModelTest: AccountDrivenTestBase {

    var viewModel: EditableAccountSettingsViewModel?

    var actual: State?
    var expected: State?
    var expectations: TestExpectations?
    var talbeViewModel: EditableAccountSettingsTableViewModel?

    override func setUp() {
        super.setUp()

        viewModel = EditableAccountSettingsViewModel(account: account)
        talbeViewModel = EditableAccountSettingsTableViewModel(account: account)
        viewModel?.tableViewModel = talbeViewModel
        let verifiableAccountMock =  VerifiableAccountMock()
        verifiableAccountMock.delegate = self
        viewModel?.verifiableAccount = verifiableAccountMock
        viewModel?.delegate = self
        setDefaultActualState()
    }

    override func tearDown() {
        actual = nil
        expected = nil
        viewModel = nil
        expectations = nil
        talbeViewModel = nil
        viewModel?.delegate = nil
        viewModel?.verifiableAccount = nil
        super.tearDown()
    }

    func testHandleSaveButtonSucceed() {
        // GIVEN
        expected = State(didCallShowLoadingView: true,
                         didCallHideLoadingView: true,
                         didCallPopViewController: true,
                         didSaveVerifiableAccount: true)
        expectations = TestExpectations(testCase: self, expected: expected)

        // WHEN
        viewModel?.handleSaveButton()
        waitForExpectations(timeout: TestUtil.waitTime)

        //THEN
        assertExpectations()
    }

    func testHandleSaveButtonInputsFail() {
        // GIVEN
        expected = State(didCallShowErrorAlert: true,
                         didCallShowLoadingView: true,
                         didCallHideLoadingView: true)
        expectations = TestExpectations(testCase: self, expected: expected)
        talbeViewModel?.name = ""

        // WHEN
        viewModel?.handleSaveButton()
        waitForExpectations(timeout: TestUtil.waitTime)

        //THEN
        assertExpectations()
    }
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
        XCTAssertEqual(expected.didSaveVerifiableAccount, actual.didSaveVerifiableAccount)

        //In case some if missing or added but not checked
        XCTAssertEqual(expected, actual)
    }
}

// MARK: - EditableAccountSettingsViewModelDelegate

extension EditableAccountSettingsViewModelTest: EditableAccountSettingsViewModelDelegate {
    func showErrorAlert(error: Error) {
        actual?.didCallShowErrorAlert = true
        expectations?.showErrorAlertExpectation?.fulfill()
    }

    func showLoadingView() {
        actual?.didCallShowLoadingView = true
        expectations?.showLoadingViewExpectation?.fulfill()
    }

    func hideLoadingView() {
        actual?.didCallHideLoadingView = true
        expectations?.hideLoadingViewExpectation?.fulfill()
    }

    func popViewController() {
        actual?.didCallPopViewController = true
        expectations?.popViewControllerExpectation?.fulfill()
    }
}

// MARK: - VerifiableAccountMockDelegate

extension EditableAccountSettingsViewModelTest: VerifiableAccountMockDelegate {
    func didSaveVerifiableAccount() {
        actual?.didSaveVerifiableAccount = true
        expectations?.saveVerifiableAccountExpectation?.fulfill()
    }
}

// MARK: - Helper Protocols

protocol VerifiableAccountMockDelegate: class {
    func didSaveVerifiableAccount()
}

// MARK: - Helping Structures

extension EditableAccountSettingsViewModelTest {
    struct State: Equatable {
        var didCallShowErrorAlert: Bool = false
        var didCallShowLoadingView: Bool = false
        var didCallHideLoadingView: Bool = false
        var didCallPopViewController: Bool = false
        var didSaveVerifiableAccount: Bool = false
    }

    final class TestExpectations {
        var showErrorAlertExpectation: XCTestExpectation?
        var showLoadingViewExpectation: XCTestExpectation?
        var hideLoadingViewExpectation: XCTestExpectation?
        var popViewControllerExpectation: XCTestExpectation?
        var saveVerifiableAccountExpectation: XCTestExpectation?

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
            if expected?.didCallPopViewController == true {
                popViewControllerExpectation = testCase.expectation(description: "popViewController")
            }
            if  expected?.didSaveVerifiableAccount == true {
                saveVerifiableAccountExpectation = testCase.expectation(description: "saveVerifiableAccount")
            }
        }
    }

    final class VerifiableAccountMock: VerifiableAccount {

        weak var delegate: VerifiableAccountMockDelegate?

        override func save(completion: ((Success) -> ())? = nil) throws {
            try super.save { [weak self] success in
                self?.delegate?.didSaveVerifiableAccount()
                completion?(success)
            }
        }
    }
}
