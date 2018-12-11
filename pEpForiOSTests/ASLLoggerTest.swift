//
//  ASLLoggerTest.swift
//  pEpForiOSTests
//
//  Created by Dirk Zimmermann on 05.12.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import pEpForiOS

class ASLLoggerTest: XCTestCase {
    func testSimple() {
        let logger = ASLLogger()
        let logMessage1 = "blah (1)"
        let logMessage2 = "more blah (2)"
        let entity = "WhatTheBlah"
        logger.saveLog(severity: .error, entity: entity, description: logMessage1, comment: "ui")
        logger.saveLog(severity: .error, entity: entity, description: logMessage2, comment: "ui")
        let logString = logger.retrieveLog()
        XCTAssertFalse(logString.isEmpty)
        XCTAssertTrue(logString.contains(find: logMessage1))
        XCTAssertTrue(logString.contains(find: logMessage2))
    }
}
