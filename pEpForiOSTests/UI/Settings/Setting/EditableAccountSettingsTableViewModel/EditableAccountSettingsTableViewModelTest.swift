//
//  EditableAccountSettingsTableViewModelTest.swift
//  pEpForiOSTests
//
//  Created by Alejandro Gelos on 04/11/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import XCTest
@testable import pEpForiOS

final class EditableAccountSettingsTableViewModelTest: AccountDrivenTestBase {

    var viewModel: EditableAccountSettingsTableViewModel?

    var actual: State?
    var expected: State?
    var validatedInputs: EditableAccountSettingsTableViewModel.TableInputs? {
        didSet {
            guard validatedInputs != nil else { return }
            actual?.didValidateInputs = true
        }
    }

    override func setUp() {
        super.setUp()

        viewModel = EditableAccountSettingsTableViewModel(account: account, delegate: self)
        setDefaultActualState()
    }

    override func tearDown() {
        actual = nil
        expected = nil
        viewModel = nil
        viewModel?.delegate = nil
        
        super.tearDown()
    }

    func testValidateInputsSucceed() {
        // GIVEN
        expected = State(didValidateInputs: true)

        // WHEN
        validatedInputs = try? viewModel?.validateInputs()

        //THEN
        assertExpectations()
    }

    func testValidateInputsImapFail() {
        // GIVEN
        expected = State()
        viewModel?.imapServer = nil


        // WHEN
        validatedInputs = try? viewModel?.validateInputs()

        //THEN
        assertExpectations()
    }

    func testValidateInputsSMPTFail() {
        // GIVEN
        expected = State()
        viewModel?.smtpServer = nil


        // WHEN
        validatedInputs = try? viewModel?.validateInputs()

        //THEN
        assertExpectations()
    }

    func testValidateInputsNameFail() {
        // GIVEN
        expected = State()
        viewModel?.name = ""


        // WHEN
        validatedInputs = try? viewModel?.validateInputs()

        //THEN
        assertExpectations()
    }

    func testValidateInputsLoginNameFail() {
        // GIVEN
        expected = State()
        viewModel?.imapUsername = ""
        viewModel?.smtpUsername = ""


        // WHEN
        validatedInputs = try? viewModel?.validateInputs()

        //THEN
        assertExpectations()
    }
}

// MARK: - Private

extension EditableAccountSettingsTableViewModelTest {
    private func setDefaultActualState() {
        actual = State()
    }

    private func assertExpectations() {
        guard let expected = expected,
            let actual = actual else {
                XCTFail()
                return
        }

        XCTAssertEqual(expected.didCallReloadTable, actual.didCallReloadTable)
        XCTAssertEqual(expected.didValidateInputs, actual.didValidateInputs)

        //In case some if missing or added but not checked
        XCTAssertEqual(expected, actual)
    }
}

// MARK: - EditableAccountSettingsTableViewModelDelegate

extension EditableAccountSettingsTableViewModelTest: EditableAccountSettingsTableViewModelDelegate {
    func reloadTable() {
        actual?.didCallReloadTable = true
    }
}

// MARK: - Helping Structures

extension EditableAccountSettingsTableViewModelTest {
    struct State: Equatable {
        var didCallReloadTable: Bool = false
        var didValidateInputs: Bool = false
    }
}
