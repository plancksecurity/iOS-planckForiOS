//
//  LoggerTest.swift
//  pEpForiOSTests
//
//  Created by Dirk Zimmermann on 18.12.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import pEpForiOS
@testable import MessageModel

class LoggerTest: XCTestCase {
    func testSimple() {
        let log1 = Logger(subsystem: "sys1", category: "cat1")
        log1.log("hi")
    }
}
