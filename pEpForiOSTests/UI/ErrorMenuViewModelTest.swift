//
//  ErrorMenuViewModelTest.swift
//  pEpForiOSTests
//
//  Created by Martín Brude on 10/5/22.
//  Copyright © 2022 p≡p Security S.A. All rights reserved.
//

import XCTest
@testable import pEpForiOS
@testable import MessageModel

class ErrorMenuViewModelTest: XCTestCase {

    func testNumberOfRows() {
        let delegate = ErrorMenuVMDelegate()
        let errorMenuViewModel = ErrorMenuViewModel(delegate: delegate)
        XCTAssertEqual(errorMenuViewModel.count, ErrorMenuViewModel.RowIdentifier.allCases.count)
    }
}

class ErrorMenuVMDelegate : ErrorMenuViewModelDelegate {
    func closeNotification() {

    }

    func showAlerView() {

    }
}
