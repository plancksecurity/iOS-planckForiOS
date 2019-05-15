//
//  LoggerTest.swift
//  pEpForiOSTests
//
//  Created by Dirk Zimmermann on 18.12.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import XCTest

import pEpForiOS
import MessageModel
import pEpIOSToolbox

class LoggerTest: XCTestCase {
    func testSimple() {
        let log1 = Logger(subsystem: "sys1", category: "cat1")
        log1.log("1 hi (standalone)")
        log1.log("2 hi (one number): %d", 2)
        log1.log("3 hi (one number plus string): %d %@", 2, "parameters")
    }
}
