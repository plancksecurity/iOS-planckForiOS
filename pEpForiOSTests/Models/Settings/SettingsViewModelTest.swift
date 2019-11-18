//
//  SettingsViewModelTest.swift
//  pEpForiOSTests
//
//  Created by Borja González de Pablo on 01/10/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import XCTest
@testable import pEpForiOS
@testable import MessageModel

final class SettingsViewModelTest: CoreDataDrivenTestBase {

    var settingsVM : SettingsViewModel!

    override class func setUp() {
        super.setUp()
        KeySyncDeviceGroupUtilMoc.resetMoc()
    }

    func givenThereAreTwoAccounts() {
        _ = SecretTestData().createWorkingCdAccount(number: 1, context: moc)
        moc.saveAndLogErrors()
    }

    //Number of sections corresponding to SettingsSectionViewModel.SectionType count
    let sections = 5

    func testNumberOfSections() {
        setupViewModel()
        KeySyncDeviceGroupUtilMoc.deviceGroupValueForTest  = .sole
        XCTAssertEqual(settingsVM.count, sections)
    }
    
    func testDeleteAccountWithOnlyOneAccount() {
        setupViewModel()
        let cellsBefore = settingsVM[0].count

        settingsVM.delete(section: 0, cell: 0)
        let cellsAfter = settingsVM[0].count

        XCTAssertEqual(cellsAfter, cellsBefore - 1)

        let thereIsNoAccount = settingsVM.noAccounts()

        XCTAssertTrue(thereIsNoAccount)
    }

    func testDeleteAccountWithMoreThanOneAccount() {
        givenThereAreTwoAccounts()
        setupViewModel()

        let accountCellsBefore = settingsVM[0].count

        settingsVM.delete(section: 0, cell: 0)
        let accountCellsAfter = settingsVM[0].count

        let thereIsOneLessAccount = accountCellsBefore - 1 == accountCellsAfter

        XCTAssertTrue(thereIsOneLessAccount)
    }

    func testDeleteAccountWithMoreThanOneAccountUpdatesDefaultAccount() {

        givenThereAreTwoAccounts()
        setupViewModel()

        let firstAccountPosition = (0,0)
        let secondAccountPosition = (0,0)
        let defaultAddress = (settingsVM[0][0] as? SettingsCellViewModel)?.account?.user.address

        AppSettings.shared.defaultAccount = defaultAddress
        XCTAssertEqual(AppSettings.shared.defaultAccount, defaultAddress)

        settingsVM.delete(section: firstAccountPosition.0, cell: firstAccountPosition.1)

        XCTAssertNotEqual(AppSettings.shared.defaultAccount, defaultAddress)
        XCTAssertNotNil(AppSettings.shared.defaultAccount)
        let newDefaultAddress = (settingsVM[secondAccountPosition.0][secondAccountPosition.1] as? SettingsCellViewModel)?.account?.user.address
        XCTAssertEqual(AppSettings.shared.defaultAccount, newDefaultAddress)

    }

    func testLeaveDeviceGroupPressed() {
        // GIVEN
        setupViewModel()
        
        // WHEN
        _ = settingsVM.leaveDeviceGroupPressed()

        // THEN
        XCTAssertTrue(KeySyncDeviceGroupUtilMoc.didCallLeaveDeviceGroup)
        guard let section = keySyncSection() else { return }
        for cell in section.cells {
            guard let cell = cell as? SettingsActionCellViewModel else { continue }
            XCTAssertFalse(cell.type == .leaveKeySyncGroup)
        }
    }
}

// MARK: - Private
extension SettingsViewModelTest {
    private func setupViewModel() {
        settingsVM = SettingsViewModel()
    }

    private func keySyncSection() -> SettingsSectionViewModel? {
        for section in settingsVM.sections {
            guard section.type == SettingsSectionViewModel.SectionType.keySync else { continue }
            return section
        }
        return nil
    }
}
