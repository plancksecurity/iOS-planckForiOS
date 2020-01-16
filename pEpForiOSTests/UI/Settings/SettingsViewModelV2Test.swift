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

    override func setUp() {
        super.setUp()
        setupViewModel()
    }

    //Number of sections corresponding to SettingsViewModelV2.SectionType count
    let sections = 5

    func testNumberOfSections() {
        XCTAssertEqual(settingsVM.count, sections)
    }

    func testNumberOfRowsForSectionInFirstPosition() {
        let numberOfAccounts = Account.all().count

        ///Position of the first section
        let indexPath = IndexPath(row: 0, section: 0)

        /// The number of rows in this section corresponds to the number of accounts plus one row for resetting all.
        let numberOfRows = numberOfAccounts + 1

        XCTAssertEqual(settingsVM.section(for: indexPath).rows.count, numberOfRows)
    }

    func testNumberOfRowsForSectionInSecondPosition() {
        ///Position of the second section
        let indexPath = IndexPath(row: 0, section: 1)
        let numberOfRows = 6

        XCTAssertEqual(settingsVM.section(for: indexPath).rows.count, numberOfRows)
    }

    func testNumberOfRowsForSectionInThirdPosition() {
        ///Position of the third section
        let indexPath = IndexPath(row: 0, section: 2)
        let numberOfRows = 2

        XCTAssertEqual(settingsVM.section(for: indexPath).rows.count, numberOfRows)
    }

    func testNumberOfRowsForSectionInFourthPosition() {
        ///Position of the fourth section
        let indexPath = IndexPath(row: 0, section: 3)
        let numberOfRows = 1

        XCTAssertEqual(settingsVM.section(for: indexPath).rows.count, numberOfRows)
    }

    func testNumberOfRowsForSectionInFivePosition() {
        ///Position of the five section
        let indexPath = IndexPath(row: 0, section: 4)
        let numberOfRows = 1

        XCTAssertEqual(settingsVM.section(for: indexPath).rows.count, numberOfRows)
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

//    private func keySyncSection() -> SettingsSectionViewModel? {
//        for section in settingsVM.sections {
//            guard section.type == SettingsSectionViewModel.SectionType.keySync else { continue }
//            return section
//        }
//        return nil
//    }
