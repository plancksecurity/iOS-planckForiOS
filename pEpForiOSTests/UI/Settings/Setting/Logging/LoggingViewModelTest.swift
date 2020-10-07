//
//  LoggingViewModelTest.swift
//  pEpForiOSTests
//
//  Created by Dirk Zimmermann on 07.10.20.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import pEpForiOS
import pEpIOSToolbox

class LoggingViewModelTest: XCTestCase {
    let logUpdateInterval = 0.3

    func testEmpty() {
        let vm = LoggingViewModel()
        vm.updateInterval = logUpdateInterval
        let expLogged = expectation(description: "expLogged")
        let delegateMock = LoggingMock(expLogged: expLogged)
        vm.delegate = delegateMock
        wait(for: [expLogged], timeout: TestUtil.waitTimeCoupleOfSeconds)
        XCTAssertEqual(delegateMock.logEntries.count, 0)
    }

    func testCoupleOfLines() {
        let vm = LoggingViewModel()
        vm.updateInterval = logUpdateInterval
        let expLogged = expectation(description: "expLogged")
        let delegateMock = LoggingMock(expLogged: expLogged)
        vm.delegate = delegateMock

        let logLines = ["line1", "line2", "line3"]
        for line in logLines {
            Log.shared.logWarn(message: line)
        }

        wait(for: [expLogged], timeout: TestUtil.waitTimeCoupleOfSeconds)
        XCTAssertEqual(delegateMock.logEntries, logLines)
    }

    func testRepeatingCoupleOfLines() {
        let vm = LoggingViewModel()
        vm.updateInterval = logUpdateInterval
        let expLogged = expectation(description: "expLogged")
        expLogged.expectedFulfillmentCount = 2
        let delegateMock = LoggingMock(expLogged: expLogged)
        vm.delegate = delegateMock

        let logLines = ["line1", "line2", "line3"]
        for line in logLines {
            Log.shared.logWarn(message: line)
        }

        wait(for: [expLogged], timeout: TestUtil.waitTimeCoupleOfSeconds)
        XCTAssertEqual(delegateMock.logEntries, logLines)
    }
}

class LoggingMock: LogViewModelDelegate {
    var logEntries = [String]()
    var expLogged: XCTestExpectation?

    init(expLogged: XCTestExpectation? = nil) {
        self.expLogged = expLogged
    }

    func updateLogContents(logString: String) {
        if !logString.isEmpty {
            logEntries.append(logString)
        }
        expLogged?.fulfill()
    }
}
