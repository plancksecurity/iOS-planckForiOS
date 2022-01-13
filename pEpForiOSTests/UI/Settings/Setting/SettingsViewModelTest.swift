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

    //Number of sections corresponding to SettingsViewModel.SectionType count

    let sections = SettingsViewModel.SectionType.allCases.count

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
        let removeFolderViewCollapsedStateOfAccountWithExpectation = expectation(description: "removeFolderViewCollapsedStateOfAccountWithExpectation")
        let appSettingsMock = MockAppSettings(removeFolderViewCollapsedStateOfAccountWithExpectation: removeFolderViewCollapsedStateOfAccountWithExpectation)
        setupViewModel(delegate: delegate, appSettings: appSettingsMock)
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
        waitForExpectations(timeout: TestUtil.waitTime)
    }

    func testDeleteAccountWithMoreThanOneAccount() {
        givenThereAreTwoAccounts()
        let delegate = SettingsViewModeldelegate()
        let removeFolderViewCollapsedStateOfAccountWithExpectation = expectation(description: "removeFolderViewCollapsedStateOfAccountWithExpectation")
        let appSettingsMock = MockAppSettings(removeFolderViewCollapsedStateOfAccountWithExpectation: removeFolderViewCollapsedStateOfAccountWithExpectation)
        setupViewModel(delegate: delegate, appSettings: appSettingsMock)
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
        waitForExpectations(timeout: TestUtil.waitTime)
    }

    func testHandleExportDBsPressed() {
        let delegate = SettingsViewModeldelegate()
        let exportDBsexpectation = expectation(description: "export dbs")
        let mockFileExportUtil = MockFileExportUtil(exportDBsexpectation: exportDBsexpectation)
        let vm = SettingsViewModel(delegate: delegate, fileExportUtil:mockFileExportUtil)
        vm.handleExportDBsPressed()
        wait(for: [exportDBsexpectation], timeout: TestUtil.waitTime)
    }
}

// MARK: - Private

extension SettingsViewModelTest {
    private func setupViewModel(delegate: SettingsViewModelDelegate, appSettings: AppSettingsProtocol? = nil) {
        if settingsVM == nil {
            if let appSettings = appSettings {
                settingsVM = SettingsViewModel(delegate: delegate, appSettings:appSettings)
            } else {
                settingsVM = SettingsViewModel(delegate: delegate)
            }
        }
    }
}

class MockFileExportUtil : FileExportUtilProtocol {

    private var exportDBsexpectation: XCTestExpectation?

    init(exportDBsexpectation: XCTestExpectation) {
        self.exportDBsexpectation = exportDBsexpectation
    }
    public func exportDatabases() throws {
        if let exportDBsexpectation = exportDBsexpectation {
            exportDBsexpectation.fulfill()
        }
    }
}

// MARK: - delegate mocks

class SettingsViewModeldelegate: SettingsViewModelDelegate {
    
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

    func showDBExportSuccess() {
        XCTFail()
    }

    func showDBExportFailed() {
        XCTFail()
    }
}
