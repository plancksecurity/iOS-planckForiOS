//
//  PEPLoggerTests.swift
//  PEPLoggerTests
//
//  Created by Alejandro Gelos on 16/01/2020.
//  Copyright © 2020 Alejandro Gelos. All rights reserved.
//

import XCTest
@testable import PEPLogger

/// For DEBUG only.
final class LoggerTest: XCTestCase {

    private var actual: State?
    private var expected: State?

    //Message to test log
    private let messageToLog = "Test message to log"
    //Error to test log
    private let errorToLog = TestError.testError

    override func setUp() {
        super.setUp()

        setDefaultActualState()
    }

    override func tearDown() {
        actual = nil
        expected = nil

        super.tearDown()
    }

    /// Singleton test
    func testShared() {
        XCTAssertNotNil(Logger.shared)
        XCTAssertTrue(Logger.shared === Logger.shared)
    }

    /// Test initial value
    func testModeDefaultValue() {
        XCTAssertEqual(Logger.shared.mode, .normal)
    }

    /// Test changing mode
    func testMode() {
        // GIVEN
        let initialValue = Logger.shared.mode

        // WHEN
        Logger.shared.mode = .verbose

        //THEN
        XCTAssertEqual(Logger.shared.mode, .verbose)
        XCTAssertNotEqual(Logger.shared.mode, initialValue)
    }

    /// <#Description#>
    func testdebug(){
        // GIVEN
        Logger.shared.mode = .normal
        guard let errorDescription = errorToLog.errorDescription else {
            XCTFail()
            return
        }

        // WHEN
        Logger.shared.debug(message: messageToLog)
        Logger.shared.debug(error: errorToLog)

        // THEN
        let log = Logger.shared.log
        XCTAssertTrue(log.contains(messageToLog))
        XCTAssertTrue(log.contains(#function))
        XCTAssertTrue(log.contains(#file))

        XCTAssertTrue(log.contains(errorDescription))
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
    private struct State: Equatable {
        var log: String = ""
        var mode: Logger.Mode = .normal
    }

    /// Error to test log
    private enum TestError: Error, LocalizedError {
        case testError

        var errorDescription: String? {
            switch self {
            case .testError:
                return "Test error description to log"
            }
        }
    }
}

// MARK: - Private

extension LoggerTest {
    private func setDefaultActualState() {
        actual = State()
    }
}
