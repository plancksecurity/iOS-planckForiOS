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
        let logMessage = "*** more blah"
        logger.saveLog(severity: .error, entity: "blah", description: logMessage, comment: "ui")
        let logString = logger.retrieveLog()
        XCTAssertFalse(logString.isEmpty)
        XCTAssertTrue(logString.contains(find: logMessage))
        if logString.isEmpty {
            print("*** log is empty")
        } else if !logString.contains(find: logMessage) {
            print("*** have log but doesn't contain our stuff")
        }
    }
}
