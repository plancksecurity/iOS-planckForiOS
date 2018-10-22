//
//  UnecryptedSubjectViewModel.swift
//  pEpForiOSTests
//
//  Created by Borja González de Pablo on 19/10/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import XCTest
@testable import pEpForiOS
@testable import MessageModel

class UnecryptedSubjectViewModelTest: CoreDataDrivenTestBase {
    var viewModel: UnecryptedSubjectViewModel!

    override func setUp() {
        super.setUp()
        viewModel = UnecryptedSubjectViewModel()
    }

    public func testSwitch() {

        viewModel.setSwitch(value: true)

        XCTAssertEqual(true, !AppSettings.unencryptedSubjectEnabled)

        var switchValue = viewModel.switchValue()

        XCTAssertEqual(true, switchValue)

        viewModel.setSwitch(value: false)

        XCTAssertEqual(false, !AppSettings.unencryptedSubjectEnabled)

        switchValue = viewModel.switchValue()

        XCTAssertEqual(false, switchValue)

    }
}
