//
//  PassiveModeViewModelTest.swift
//  pEpForiOSTests
//
//  Created by Borja González de¯ Pablo on 19/10/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import XCTest
@testable import pEpForiOS
@testable import MessageModel

class PassiveModeViewModelTest: CoreDataDrivenTestBase {

    var viewModel: PassiveModeViewModel!

    override func setUp() {
        super.setUp()
        viewModel = PassiveModeViewModel()
    }

    public func testSwitch() {

        viewModel.setSwitch(value: true)

        XCTAssertEqual(true, AppSettings.passiveMode)

        var switchValue = viewModel.switchValue()

        XCTAssertEqual(true, switchValue)

        viewModel.setSwitch(value: false)

        XCTAssertEqual(false, AppSettings.passiveMode)

        switchValue = viewModel.switchValue()

        XCTAssertEqual(false, switchValue)

    }
}
