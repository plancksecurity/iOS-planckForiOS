//
//  LoggerTest.swift
//  pEpIOSToolboxTests
//
//  Created by Dirk Zimmermann on 07.10.20.
//  Copyright © 2020 pEp Security SA. All rights reserved.
//

import XCTest

import pEpIOSToolbox

class LoggerTest: XCTestCase {
    func testNothingHappens() throws {
        let s1 = Log.shared.getLatestLogString()
        let s2 = Log.shared.getLatestLogString()
        XCTAssertEqual(s1, s2)
    }

    func testAppendLogString() throws {
        let warningString = "Warning!"
        let s1 = Log.shared.getLatestLogString()
        Log.shared.warn("%@", warningString)
        let s2 = Log.shared.getLatestLogString()
        XCTAssertNotEqual(s1, s2)
        XCTAssertTrue(s2.containsString(warningString))
    }
}
