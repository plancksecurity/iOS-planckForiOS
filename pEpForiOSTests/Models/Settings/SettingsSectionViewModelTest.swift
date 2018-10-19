//
//  SettingsSectionViewModelTest.swift
//  pEpForiOSTests
//
//  Created by Borja González de Pablo on 02/10/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import XCTest
@testable import pEpForiOS
@testable import MessageModel

class SettignsSectionViewModelTest: CoreDataDrivenTestBase {

    var viewModel: SettingsSectionViewModel!

    func testDeleteCell(){
        setUpViewModel()
        let beforeCount = viewModel.count
        viewModel.delete(cell: 0)
        let afterCount = viewModel.count
        XCTAssertEqual(afterCount, beforeCount - 1)
    }

    func testInvalidCells() {
        setUpViewModel()
        let validCell = viewModel.cellIsValid(cell: viewModel.count)
        XCTAssertFalse(validCell)
    }

    func testValidCells() {
        setUpViewModel()
        let validCell = viewModel.cellIsValid(cell: 0)
        XCTAssertTrue(validCell)
    }


    //MARK: Initialization
    func setUpViewModel(){
        viewModel = SettingsSectionViewModel(type: .globalSettings)
    }
}
