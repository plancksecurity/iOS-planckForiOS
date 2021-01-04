//
//  SettingsViewModelTest.swift
//  pEpForiOSTests
//
//  Created by Xavier Algarra on 16/01/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import XCTest
@testable import pEpForiOS
@testable import MessageModel

class SettingsViewModelTest: AccountDrivenTestBase {

    var settingsVM : SettingsViewModel!

    func givenThereAreTwoAccounts() {
        let account = TestData().createWorkingAccount()
        account.session.commit()
    }

    //Number of sections corresponding to SettingsViewModelV2.SectionType count
    let sections = 5

    func testNumberOfSections() {
        let delegate = SettingsViewModeldelegate()
        setupViewModel(delegate: delegate)
        XCTAssertEqual(settingsVM.count, sections)
    }

    func testNumberOfRowsForSectionInFirstPositionWith1Account() {
        let delegate = SettingsViewModeldelegate()
        setupViewModel(delegate: delegate)
        let numberOfStaticCellInAccountsSection = 1
        let numberOfAccounts = Account.all().count
        ///Position of the first section
        let indexPath = IndexPath(row: 0, section: 0)

        /// The number of rows in this section corresponds to the number of accounts plus one row for resetting all.
        let numberOfRows = numberOfAccounts + numberOfStaticCellInAccountsSection

        XCTAssertEqual(settingsVM.section(for: indexPath).rows.count, numberOfRows)
    }

    func testNumberOfRowsForSectionInFirstPositionWithMoreThan1Account() {
        givenThereAreTwoAccounts()
        let delegate = SettingsViewModeldelegate()
        setupViewModel(delegate: delegate)
        let numberOfStaticCellInAccountsSection = 1
        let numberOfAccounts = Account.all().count
        ///Position of the first section
        let indexPath = IndexPath(row: 0, section: 0)

        /// The number of rows in this section corresponds to the number of accounts plus one row for resetting all.
        let numberOfRows = numberOfAccounts + numberOfStaticCellInAccountsSection

        XCTAssertEqual(settingsVM.section(for: indexPath).rows.count, numberOfRows)
    }

    func testSwitchBehaviorOnProtectMessageSubject() {
        let delegate = SettingsViewModeldelegate()
        setupViewModel(delegate: delegate)
        let globalSettingsSectionIndex = 1
        let protectRowIndex = 5
        let indexPath = IndexPath(row: 0, section: globalSettingsSectionIndex)
        let globalSettingsSection = settingsVM.section(for: indexPath)
        if let passiveModeRow = globalSettingsSection.rows[protectRowIndex] as? SettingsViewModel.ActionRow,
            let action = passiveModeRow.action {
            let previousValue = AppSettings.shared.unencryptedSubjectEnabled
            action()
            let newPassiveMode = AppSettings.shared.unencryptedSubjectEnabled
            XCTAssert(previousValue != newPassiveMode)
        }
    }
    
    func testSwitchBehaviorOnPepSync () {
        let delegate = SettingsViewModeldelegate()
        setupViewModel(delegate: delegate)
        let PEPsyncSectionIndex = 1
        let enablePEPSyncRowIndex = 0
        let indexPath = IndexPath(row: 0, section: PEPsyncSectionIndex)
        let globalSettingsSection = settingsVM.section(for: indexPath)
        if let PEPSyncEnableRow =
            globalSettingsSection.rows[enablePEPSyncRowIndex] as? SettingsViewModel.SwitchRow {
            let previousValue = KeySyncUtil.isKeySyncEnabled
            PEPSyncEnableRow.action(!previousValue)
            let newPEPSyncStatus = KeySyncUtil.isKeySyncEnabled
            XCTAssert(previousValue != newPEPSyncStatus)
        }
    }
    
    func testDeleteAccountWithOnlyOneAccount() {
        let delegate = SettingsViewModeldelegate()
        setupViewModel(delegate: delegate)
        let firstIndexPath = IndexPath(row: 0, section: 0)
        let firstSection = settingsVM.section(for: firstIndexPath)
        let cellsBefore = firstSection.rows.count
        let firstSectionRows = firstSection.rows
        if let row = firstSectionRows.first as? SettingsViewModel.ActionRow,
            let action = row.action {
            action()
        }
        let cellsAfter = settingsVM.section(for: firstIndexPath).rows.count
        XCTAssertEqual(cellsBefore, cellsAfter + 1)
    }

    func testDeleteAccountWithMoreThanOneAccount() {
        givenThereAreTwoAccounts()
        let delegate = SettingsViewModeldelegate()
        setupViewModel(delegate: delegate)
        testDeleteAccountWithOnlyOneAccount()
    }
}

// MARK: - Private

extension SettingsViewModelTest {
    private func setupViewModel(delegate: SettingsViewModelDelegate) {
        if settingsVM == nil {
            settingsVM = SettingsViewModel(delegate: delegate)
        }
    }
}

// MARK: - delegate mocks

class SettingsViewModeldelegate: SettingsViewModelDelegate {
    func showCantDeleteAccountAlert() {
        XCTFail()
    }

    func showNoAccountsView() {
        XCTFail()
    }

    func showLoadingView() {
        XCTFail()
    }
    
    func hideLoadingView() {
        XCTFail()
    }
    
    func showExtraKeyEditabilityStateChangeAlert(newValue: String) {
        XCTFail()
    }

    func showResetAllWarning(callback: @escaping SettingsViewModel.ActionBlock) {
        XCTFail()
    }
}
