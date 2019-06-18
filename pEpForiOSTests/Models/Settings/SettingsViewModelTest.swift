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

class SettingsViewModelTest: CoreDataDrivenTestBase {

    var settingsVM : SettingsViewModel!
    var keySyncDeviceGroupServiceMoc: KeySyncDeviceGroupServiceMoc!

    //Number of sections corresponding to SettingsSectionViewModel.SectionType count
    let sections = 3

    func testNumberOfSections() {

        setupViewModel()

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

    fileprivate func setupViewModel() {
        keySyncDeviceGroupServiceMoc = KeySyncDeviceGroupServiceMoc()
        settingsVM = SettingsViewModel(keySyncDeviceGroupServiceMoc)
    }

    func givenThereAreTwoAccounts() {
        _ = SecretTestData().createWorkingCdAccount(number: 1, context: moc)
        moc.saveAndLogErrors()
    }

    func testLeaveDeviceGroupPressed() {
        // GIVEN
        setupViewModel()
        
        // WHEN
        settingsVM.leaveDeviceGroupPressed()

        // THEN
        XCTAssertTrue(keySyncDeviceGroupServiceMoc.didCallLeaveDeviceGroup)
    }
}
