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
    var keySyncDeviceGroupServiceMoc: KeySyncDeviceGroupServiceMoc!
    var messageModelServiceMoc: MessageModelServiceMoc!


    //Number of sections corresponding to SettingsSectionViewModel.SectionType count
    let sections = 4

    func testNumberOfSections() {
        setupViewModel()
        keySyncDeviceGroupServiceMoc.deviceGroupValueForTest  = .sole
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

    func givenThereAreTwoAccounts() {
        _ = SecretTestData().createWorkingCdAccount(number: 1, context: moc)
        moc.saveAndLogErrors()
    }

    func testLeaveDeviceGroupPressed() {
        // GIVEN
        setupViewModel()
        
        // WHEN
        _ = settingsVM.leaveDeviceGroupPressed()

        // THEN
        XCTAssertTrue(keySyncDeviceGroupServiceMoc.didCallLeaveDeviceGroup)
        guard let section = keySyncSection() else { return }
        for cell in section.cells {
            guard let cell = cell as? SettingsActionCellViewModel else { continue }
            XCTAssertFalse(cell.type == .leaveKeySyncGroup)
        }
    }

    func testKeySyncEnabledSetTrue() {
        // GIVEN
        setupViewModel()

        // WHEN
        guard let section = keySyncSection() else {
            XCTFail()
            return
        }
        for cell in section.cells {
            guard let cell = cell as? EnableKeySyncViewModel else { continue }
            cell.setSwitch(value: true)
        }

        // THEN
        XCTAssertTrue(messageModelServiceMoc.enableKeySyncWasCalled)
    }

    func testKeySyncEnabledSetFalse() {
        // GIVEN
        setupViewModel()

        // WHEN
        for section in settingsVM.sections {
            guard section.type == SettingsSectionViewModel.SectionType.keySync else { continue }
            for cell in section.cells {
                guard let cell = cell as? EnableKeySyncViewModel else { continue }
                cell.setSwitch(value: false)
            }
        }

        // THEN
        XCTAssertTrue(messageModelServiceMoc.disableKeySyncWasCalled)
    }
}

// MARK: - Private
extension SettingsViewModelTest {
    private func setupViewModel() {
        messageModelServiceMoc = MessageModelServiceMoc()
        keySyncDeviceGroupServiceMoc = KeySyncDeviceGroupServiceMoc()
        settingsVM = SettingsViewModel(messageModelServiceMoc, keySyncDeviceGroupServiceMoc)
    }

    private func keySyncSection() -> SettingsSectionViewModel? {
        for section in settingsVM.sections {
            guard section.type == SettingsSectionViewModel.SectionType.keySync else { continue }
            return section
        }
        return nil
    }
}
