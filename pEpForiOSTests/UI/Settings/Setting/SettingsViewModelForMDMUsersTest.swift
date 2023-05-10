//
//  SettingsViewModelForMDMUsersTest.swift
//  pEpForiOSTests
//
//  Created by Xavier Algarra on 16/01/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import XCTest
@testable import pEpForiOS
@testable import MessageModel

class SettingsViewModelForMDMUsersTest: AccountDrivenTestBase {

    var settingsVM : SettingsViewModel!

    func givenThereAreTwoAccounts() {
        let account = TestData().createWorkingAccount()
        account.session.commit()
    }

    // Number of sections corresponding to SettingsViewModel.SectionType count
    let sections = [SettingsViewModel.SectionType.accounts, SettingsViewModel.SectionType.globalSettings].count

    func testNumberOfSections() {
        let delegate = SettingsViewModeldelegate()

        setupViewModel(delegate: delegate, appSettings: MDMMockAppSettings())
        XCTAssertEqual(settingsVM.count, sections)
    }

    func testNumberOfSectionsOfMDM() {
        let delegate = SettingsViewModeldelegate()
        let mock = MockRegularUsersAppSettings()
        setupViewModel(delegate: delegate, appSettings: mock)
        XCTAssertEqual(settingsVM.count, 6)
    }

    func testNumberOfRowsForSectionInFirstPositionWith1Account() {
        let delegate = SettingsViewModeldelegate()
        setupViewModel(delegate: delegate, appSettings: MDMMockAppSettings())
        let numberOfStaticCellInAccountsSection = 1
        // In case we bring back accounts to Settings, please use this: `let numberOfAccounts = Account.all().count`
        let numberOfAccounts = 0
        ///Position of the first section
        let indexPath = IndexPath(row: 0, section: 0)

        /// The number of rows in this section corresponds to the number of accounts plus one row for resetting all.
        let numberOfRows = numberOfAccounts + numberOfStaticCellInAccountsSection

        XCTAssertEqual(settingsVM.section(for: indexPath).rows.count, numberOfRows)
    }
}

// MARK: - Private

extension SettingsViewModelForMDMUsersTest {
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
