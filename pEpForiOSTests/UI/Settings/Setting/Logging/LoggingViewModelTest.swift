//
//  LoggingViewModelTest.swift
//  pEpForiOSTests
//
//  Created by Dirk Zimmermann on 07.10.20.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import pEpForiOS

class LoggingViewModelTest: XCTestCase {
    func testEmpty() {
        let vm = LoggingViewModel()
        vm.updateInterval = 0.5
        let expLogged = expectation(description: "expLogged")
        let delegateMock = LoggingMock(expLogged: expLogged)
        vm.delegate = delegateMock
        wait(for: [expLogged], timeout: TestUtil.waitTimeCoupleOfSeconds)
        XCTAssertEqual(delegateMock.logEntries.count, 0)
    }
}

class LoggingMock: LogViewModelDelegate {
    var logEntries = [String]()
    var expLogged: XCTestExpectation?

    init(expLogged: XCTestExpectation? = nil) {
        self.expLogged = expLogged
    }

    func updateLogContents(logString: String) {
        logEntries.append(logString)
        expLogged?.fulfill()
    }
}
