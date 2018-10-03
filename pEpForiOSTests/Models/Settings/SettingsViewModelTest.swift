//
//  SettingsViewModelTest.swift
//  pEpForiOSTests
//
//  Created by Borja González de Pablo on 01/10/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import XCTest
@testable import pEpForiOS
import MessageModel

class SettingsViewModelTest: CoreDataDrivenTestBase {

    var settingsVM : SettingsViewModel!
    
    func testNumberOfSections() {
        setupViewModel()
        XCTAssertEqual(settingsVM.count, 3)
    }
    
    func testDeleteAccount() {
        setupViewModel()
        let cellsBefore = settingsVM[0].count
        settingsVM.delete(section: 0, cell: 0)
        let cellsAfter = settingsVM[0].count
        XCTAssertEqual(cellsAfter, cellsBefore - 1)
        
    }

    func testIsValidSection() {
        setupViewModel()
    }

    fileprivate func setupViewModel() {
        settingsVM = SettingsViewModel()
    }
}
