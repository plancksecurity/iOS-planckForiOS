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
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    //Number of sections corresponding to SettingsViewModelV2.SectionType count
    let sections = 5

    func testNumberOfSections() {
        XCTAssertEqual(settingsVM.count, sections)
    }

    func testNumberOfRowsInSection1() {
        let numberOfAccounts = Account.all().count
        XCTAssertEqual(settingsVM[0].rows?.count, numberOfAccounts)
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
