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

class UnencryptedSubjectViewModelTest: CoreDataDrivenTestBase {
    var viewModel: UnecryptedSubjectViewModel!

    override func setUp() {
        super.setUp()
        viewModel = UnecryptedSubjectViewModel()
    }

    public func testSwitch() {
        viewModel.setSwitch(value: true)
        XCTAssertFalse(AppSettings.shared.unencryptedSubjectEnabled)

        var switchValue = viewModel.switchValue
        XCTAssertTrue(switchValue)

        viewModel.setSwitch(value: false)
        XCTAssertTrue(AppSettings.shared.unencryptedSubjectEnabled)

        switchValue = viewModel.switchValue
        XCTAssertFalse(switchValue)
    }
}
