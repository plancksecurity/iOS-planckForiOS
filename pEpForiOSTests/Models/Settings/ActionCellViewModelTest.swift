//
//  ActionCellViewModelTest.swift
//  pEpForiOSTests
//
//  Created by Alejandro Gelos on 18/06/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import XCTest
import PEPObjCAdapterFramework

@testable import pEpForiOS

class ActionCellViewModelTest: XCTestCase {
    var actionCellViewModels: [SettingsActionCellViewModel]?

    override func setUp() {
        actionCellViewModels = [SettingsActionCellViewModel]()
        actionCellViewModels?.append(SettingsActionCellViewModel(type: .keySyncSetting))
    }

    override func tearDown() {
        actionCellViewModels = nil
    }

    func testTitleText() {
        // GIVEN
        guard let actionCellViewModels = actionCellViewModels else {
            XCTFail()
            return
        }

        // WHEN
        for actionCellViewModel in actionCellViewModels {
            switch actionCellViewModel.type {
            // THEN
            case .keySyncSetting:
                XCTAssertEqual(actionCellViewModel.title,
                               NSLocalizedString("Leave Device Group",
                                                 comment: "Settings: Cell (button) title for leaving device group"))
            case .resetAllIdentities:
                XCTFail()
            }
        }
    }

    func testTitleColor() {
        // GIVEN
        guard let actionCellViewModels = actionCellViewModels else {
            XCTFail()
            return
        }

        // WHEN
        for actionCellViewModel in actionCellViewModels {
            switch actionCellViewModel.type {
            // THEN
            case .keySyncSetting:
                XCTAssertEqual(actionCellViewModel.titleColor, UIColor.AppleRed)
            case .resetAllIdentities:
                XCTFail()
            }
        }
    }
}
