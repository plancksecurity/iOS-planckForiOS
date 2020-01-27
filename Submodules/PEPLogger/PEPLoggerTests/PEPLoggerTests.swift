//
//  PEPLoggerTests.swift
//  PEPLoggerTests
//
//  Created by Alejandro Gelos on 16/01/2020.
//  Copyright © 2020 Alejandro Gelos. All rights reserved.
//

import XCTest
@testable import PEPLogger

final class LoggerTest: XCTestCase {

    var actual: State?
    var expected: State?

    override func setUp() {
        super.setUp()

        setDefaultActualState()
    }

    override func tearDown() {
        actual = nil
        expected = nil

        super.tearDown()
    }

    /// Test shared as a Singleton
    func testShared() {
        XCTAssertNotNil(Logger.shared)
        XCTAssertTrue(Logger.shared === Logger.shared)
    }

    func testMode() {
        
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
}

// MARK: - Helping Structures

extension LoggerTest {
    /// State of the logger.
    struct State: Equatable {
        var log: String = ""
        var mode: Logger.Mode = .normal
    }
}

// MARK: - Private

extension LoggerTest {
private func setDefaultActualState() {
    actual = State()
}
