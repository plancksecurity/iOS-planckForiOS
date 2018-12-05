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
        logger.saveLog(severity: .error, entity: "blah", description: "more blah", comment: "ui")
        let content = logger.retrieveLog()
        XCTAssertTrue(content.isEmpty) // ideally, there would be content :)
    }
}
