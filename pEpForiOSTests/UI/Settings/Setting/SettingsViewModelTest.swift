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

    // Number of sections corresponding to SettingsViewModel.SectionType count
    let sections = SettingsViewModel.SectionType.allCases.count

    func testNumberOfSections() {
        let delegate = SettingsViewModeldelegate()
        setupViewModel(delegate: delegate, appSettings: MockRegularUsersAppSettings())
        XCTAssertEqual(settingsVM.count, sections)
    }

    func testNumberOfSectionsOfMDM() {
        let delegate = SettingsViewModeldelegate()
        let mock = MockRegularUsersAppSettings()
        setupViewModel(delegate: delegate, appSettings: mock)
        XCTAssertEqual(settingsVM.count, 8)
    }

    func testSwitchBehaviorOnProtectMessageSubject() {
        let delegate = SettingsViewModeldelegate()
        setupViewModel(delegate: delegate, appSettings: MockRegularUsersAppSettings())
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

    func showFeedback(title: String, message: String) {
        XCTFail()
    }

    func showTryAgain(title: String, message: String) {
        XCTFail()
    }

}
