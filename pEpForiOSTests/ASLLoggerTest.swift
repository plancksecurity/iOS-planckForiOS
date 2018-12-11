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
    /*
    func testSimple() {
        let logger = ASLLogger()
        let logMessage = "some blah_uiae_trntrntrn_uiaeduiaterntrn____unique"
        let entity = "WhatTheBlah_uiae_trntrntrn_uiaeduiaterntrn____unique"
        let comment = "UI_uiae_trntrntrn_uiaeduiaterntrn____unique"

        for num in [1..<5] {
            for sev in [LoggingSeverity.error, .warning, .info, .verbose] {
                logger.saveLog(
                    severity: sev,
                    entity: entity,
                    description: "\(logMessage) (\(num))",
                    comment: comment)
            }
        }

        logger.flush()

        let logString = logger.retrieveLog()
        XCTAssertFalse(logString.isEmpty)
        XCTAssertTrue(logString.contains(find: logMessage))
        XCTAssertTrue(logString.contains(find: "DEBUG"))
        XCTAssertTrue(logString.contains(find: "NOTICE"))
        XCTAssertTrue(logString.contains(find: "WARNING"))
        XCTAssertTrue(logString.contains(find: "ERR"))
        XCTAssertTrue(logString.contains(find: comment))
        XCTAssertTrue(logString.contains(find: entity))
    }
     */
}
