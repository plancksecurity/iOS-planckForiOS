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
        let logMessage = "more blah"
        logger.saveLog(severity: .error, entity: "blah", description: logMessage, comment: "ui")
        let expLogReceived = expectation(description: "expLogReceived")
        logger.retrieveLog() { logString in
            //XCTAssertTrue(logString.contains(find: logMessage))
            expLogReceived.fulfill()
        }
        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
        })
    }
}
