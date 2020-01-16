//
//  SettingsViewModelV2Test.swift
//  pEpForiOSTests
//
//  Created by Xavier Algarra on 16/01/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import XCTest

class SettingsViewModelV2Test: CoreDataDrivenTestBase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

//    override func tearDown() {
//        // Put teardown code here. This method is called after the invocation of each test method in the class.
//    }

    func testExample() {

    }

    func testNumberOfSections() {
        setupViewModel()
    }


    func setupViewModel() {

    }
}

// MARK: - Private
extension SettingsViewModelV2Test {
    private func setupViewModel() {
        settingsVM = Sett
    }

    private func keySyncSection() -> SettingsSectionViewModel? {
        for section in settingsVM.sections {
            guard section.type == SettingsSectionViewModel.SectionType.keySync else { continue }
            return section
        }
        return nil
    }
}
