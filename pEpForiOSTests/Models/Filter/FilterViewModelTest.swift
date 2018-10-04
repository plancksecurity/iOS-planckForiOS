//
//  FilterViewModelTest.swift
//  pEpForiOSTests
//
//  Created by Borja González de Pablo on 02/10/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import pEpForiOS
@testable import MessageModel

class FilterViewModelTest: CoreDataDrivenTestBase {

    override func setUp() {
        super.setUp()

    }

    func testCreateCorrectAccountCell() {
        givenThereAreTwoAccounts()
        let viewmodel = FilterViewModel(type: .accouts)
        XCTAssertEqual(2, viewmodel.count)
    }

    func testCreateCorrectIncludeCells() {
        let viewmodel = FilterViewModel(type: .include)
        XCTAssertEqual(2, viewmodel.count)
    }

    func testCreateCorrectOtherCells() {
        let viewmodel = FilterViewModel(type: .other)
        XCTAssertEqual(1, viewmodel.count)
    }


    //MARK: Initialization
    func givenThereAreTwoAccounts() {
        _ = SecretTestData().createWorkingCdAccount(number: 1)
        Record.saveAndWait()
    }
}
