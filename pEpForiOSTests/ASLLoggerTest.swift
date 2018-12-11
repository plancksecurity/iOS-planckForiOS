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
        let logMessage1 = "blah"
        let logMessage2 = "more blah"
        let entity = "WhatTheBlah"
        logger.saveLog(severity: .error, entity: entity, description: logMessage1, comment: "ui")
        logger.saveLog(severity: .error, entity: entity, description: logMessage2, comment: "ui")
        let logString = logger.retrieveLog()
        XCTAssertFalse(logString.isEmpty)
        XCTAssertTrue(logString.contains(find: logMessage1))
        XCTAssertTrue(logString.contains(find: logMessage2))
        print("*** logString \(logString.split(separator: "\n"))")
        if logString.isEmpty {
            print("*** log is empty")
        } else if !logString.contains(find: logMessage1) {
            print("*** have log but doesn't contain our stuff")
        }
    }
}
