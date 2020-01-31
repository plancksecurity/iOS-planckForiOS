//
//  UtilsTests.swift
//  PEPLoggerTests
//
//  Created by Alejandro Gelos on 31/01/2020.
//  Copyright © 2020 Alejandro Gelos. All rights reserved.
//

import XCTest
@testable import PEPLogger

class UtilsTests: XCTestCase {

    var file: String!
    var line: String!
    var function: String!
    var message: String!
    var level: Logger.Level!

    override func setUp() {
        file = #file
        line = String(#line)
        function = #function
        message = "Message to test new logs entries"
        level = Logger.Level.debug
    }

    override func tearDown() {
        file = nil
        line = nil
        function = nil
        message = nil
        level = nil
    }

    func testNewLogEntry() {
        // GIVEN
        // WHEN
        let textEntry = Utils.newLogEntry(level: level,
                                      file: file,
                                      line: line,
                                      function: function,
                                      message: message)

        // THEN
        XCTAssertTrue(textEntry.contains(file))
        XCTAssertTrue(textEntry.contains(line))
        XCTAssertTrue(textEntry.contains(function))
        XCTAssertTrue(textEntry.contains(message))
        XCTAssertTrue(textEntry.contains(level.rawValue))
    }

    func testNewLogDataEntry() {
        // GIVEN
        // WHEN
        let dataEntry = Utils.newLogDataEntry(level: level,
                                          file: file,
                                          line: line,
                                          function: function,
                                          message: message)

        // THEN
        guard let textEntry = String(data: dataEntry, encoding: .utf8) else {
            XCTFail()
            return
        }
        XCTAssertTrue(textEntry.contains(file))
        XCTAssertTrue(textEntry.contains(line))
        XCTAssertTrue(textEntry.contains(function))
        XCTAssertTrue(textEntry.contains(message))
        XCTAssertTrue(textEntry.contains(level.rawValue))
    }
}
