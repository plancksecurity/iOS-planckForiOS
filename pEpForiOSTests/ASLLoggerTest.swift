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
        let logMessage = "Message_\(UUID())"
        let entity = "Entity_\(UUID())"
        let comment = "Comment_\(UUID())"

        let logger = ASLLogger()

        doTheLogging(logger: logger, logMessage: logMessage, entity: entity, comment: comment)

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

    func testTooOld() {
        let logMessage = "Message_\(UUID())"
        let entity = "Entity_\(UUID())"
        let comment = "Comment_\(UUID())"

        let logger = ASLLogger()
        logger.constDate = Date(timeIntervalSinceNow: -3600)

        doTheLogging(logger: logger, logMessage: logMessage, entity: entity, comment: comment)

        let logString = logger.retrieveLog()
        XCTAssertFalse(logString.contains(find: logMessage))
        XCTAssertFalse(logString.contains(find: comment))
        XCTAssertFalse(logString.contains(find: entity))
    }

    func doTheLogging(logger: ASLLogger, logMessage: String, entity: String, comment: String) {
        for num in 1..<5 {
            for sev in [LoggingSeverity.error, .warning, .info, .verbose] {
                logger.saveLog(
                    severity: sev,
                    entity: entity,
                    description: "\(logMessage) (\(num))",
                    comment: comment)
            }
        }

        logger.flush()
    }
}
