//
//  SettingsViewModelV2Test.swift
//  pEpForiOSTests
//
//  Created by Xavier Algarra on 16/01/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import XCTest
@testable import pEpForiOS
@testable import MessageModel

class SettingsViewModelV2Test: CoreDataDrivenTestBase {

    var settingsVM : SettingsViewModelV2!

    func givenThereAreTwoAccounts() {
        _ = SecretTestData().createWorkingCdAccount(number: 1, context: moc)
        moc.saveAndLogErrors()
    }

    //Number of sections corresponding to SettingsViewModelV2.SectionType count
    let sections = 5

    func testNumberOfSections() {
        setupViewModel()
        XCTAssertEqual(settingsVM.count, sections)
    }

    func testNumberOfRowsForSectionInFirstPositionWith1Account() {
        setupViewModel()

        let numberOfAccounts = Account.all().count

        ///Position of the first section
        let indexPath = IndexPath(row: 0, section: 0)

        /// The number of rows in this section corresponds to the number of accounts plus one row for resetting all.
        let numberOfRows = numberOfAccounts + 1

        XCTAssertEqual(settingsVM.section(for: indexPath).rows.count, numberOfRows)
    }

    func testNumberOfRowsForSectionInFirstPositionWithMoreThan1Account() {
        givenThereAreTwoAccounts()
        setupViewModel()
        
        let numberOfAccounts = Account.all().count

        ///Position of the first section
        let indexPath = IndexPath(row: 0, section: 0)

        /// The number of rows in this section corresponds to the number of accounts plus one row for resetting all.
        let numberOfRows = numberOfAccounts + 1

        XCTAssertEqual(settingsVM.section(for: indexPath).rows.count, numberOfRows)
    }

    func testNumberOfRowsForSectionInSecondPosition() {
        setupViewModel()

        ///Position of the second section
        let indexPath = IndexPath(row: 0, section: 1)
        let numberOfRows = 6

        XCTAssertEqual(settingsVM.section(for: indexPath).rows.count, numberOfRows)
    }

    func testNumberOfRowsForSectionInThirdPosition() {
        setupViewModel()

        ///Position of the third section
        let indexPath = IndexPath(row: 0, section: 2)
        let numberOfRows = 2

        XCTAssertEqual(settingsVM.section(for: indexPath).rows.count, numberOfRows)
    }

    func testNumberOfRowsForSectionInFourthPosition() {
        setupViewModel()

        ///Position of the fourth section
        let indexPath = IndexPath(row: 0, section: 3)
        let numberOfRows = 1

        XCTAssertEqual(settingsVM.section(for: indexPath).rows.count, numberOfRows)
    }

    func testNumberOfRowsForSectionInFivePosition() {
        setupViewModel()

        ///Position of the five section
        let indexPath = IndexPath(row: 0, section: 4)
        let numberOfRows = 1

        XCTAssertEqual(settingsVM.section(for: indexPath).rows.count, numberOfRows)
    }

    ////---------
    func testDeleteAccountWithOnlyOneAccount() {
        setupViewModel()
        let firstIndexPath = IndexPath(row: 0, section: 0)
        let firstSection = settingsVM.section(for: firstIndexPath)
        let cellsBefore = firstSection.rows.count
        let firstSectionRows = firstSection.rows
        if let row = firstSectionRows.first as? SettingsViewModelV2.ActionRow {
            row.action(firstIndexPath)
        }

        let cellsAfter = settingsVM.section(for: firstIndexPath).rows.count
        XCTAssertEqual(cellsBefore, cellsAfter + 1)
    }

    func testDeleteAccountWithMoreThanOneAccount() {
        givenThereAreTwoAccounts()
        setupViewModel()

        testDeleteAccountWithOnlyOneAccount()
    }

    func testDeleteAccountWithMoreThanOneAccountUpdatesDefaultAccount() {
        givenThereAreTwoAccounts()
        setupViewModel()

        let accountSectionIP = IndexPath(row: 0, section: 0)
        if let firstAccountRow = settingsVM.section(for: accountSectionIP)
            .rows.first as? SettingsViewModelV2.ActionRow,
            let secondAccountRow = settingsVM.section(for: accountSectionIP)
            .rows[1] as? SettingsViewModelV2.ActionRow {

            //Test first account is setted
            AppSettings.shared.defaultAccount = firstAccountRow.title
            XCTAssertEqual(AppSettings.shared.defaultAccount, firstAccountRow.title)

            //Delete default account
            let firstSection = settingsVM.section(for: accountSectionIP)
            let firstSectionRows = firstSection.rows
            if let row = firstSectionRows.first as? SettingsViewModelV2.ActionRow {
                row.action(accountSectionIP)
            }

            //Test the first account (that was deleted) is not the default account anymore
            XCTAssertNotEqual(AppSettings.shared.defaultAccount, firstAccountRow.title)

            //Test the Default account still exists
            XCTAssertNotNil(AppSettings.shared.defaultAccount)

            //Test the second account is the default account
            XCTAssertEqual(AppSettings.shared.defaultAccount, secondAccountRow.title)
        }
    }
}

// MARK: - Private
extension SettingsViewModelV2Test {
    private func setupViewModel() {
        if settingsVM == nil {
            settingsVM = SettingsViewModelV2()
        }
    }
}
