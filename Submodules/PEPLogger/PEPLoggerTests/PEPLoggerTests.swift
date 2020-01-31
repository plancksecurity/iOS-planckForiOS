//
//  PEPLoggerTests.swift
//  PEPLoggerTests
//
//  Created by Alejandro Gelos on 16/01/2020.
//  Copyright © 2020 Alejandro Gelos. All rights reserved.
//

import XCTest
@testable import PEPLogger

/// Use logMessageTester and logErrorTester to test all loggs.
/// For DEBUG only.
final class LoggerTest: XCTestCase {
    // Unique message is generated on each call
    private var message: String {
        let currentDate = Date()
        return "Test message to log " + LoggerTest.dateFormater.string(from: currentDate)
    }

    // All errors have the same date in description. But different date from previous builds
    private let error = TestError.testError

    static private let dateFormater = DateFormatter()

    override func setUp() {
        super.setUp()
        Logger.shared.mode = .normal //default mode
        LoggerTest.dateFormater.dateFormat = "y-MM-dd H:m:ss.SSSS"
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

    func testLog() {
        // GIVEN
        let oldLog = Logger.shared.log

        // WHEN
        Logger.shared.error(error: error)
        Logger.shared.error(message: message)
        let newLog = Logger.shared.log

        // THEN
        XCTAssertNotEqual(oldLog, newLog)
        XCTAssertTrue(newLog.contains(oldLog))
        XCTAssertFalse(oldLog.contains(newLog))

        XCTAssertFalse(oldLog.contains(message))

        XCTAssertTrue(newLog.contains(message))
    }

    func testMessageDebug(){
        logMessageTester(level: .debug, message: message)
    }

    func testErrorDebug() {
        logErrorTester(level: .debug, error: error)
    }

    func testMessageInfo() {
        logMessageTester(level: .info, message: message)
    }

    func testErrorInfo() {
        logErrorTester(level: .info, error: error)
    }

    func testMessageWarn() {
        logMessageTester(level: .warn, message: message)
    }

    func testErrorWarn() {
        logErrorTester(level: .warn, error: error)
    }

    func testMessageError() {
        logMessageTester(level: .error, message: message)
    }

    func testError() {
        logErrorTester(level: .error, error: error)
    }

    func testLogPerformance() {
        for _ in 0 ..< 500 {
            Logger.shared.error(message: message)
        }
        measure {
            _ = Logger.shared.log
        }
    }
}

// MARK: - Helping Structures

extension LoggerTest {
    /// Error to test log
    private enum TestError: Error, LocalizedError {
        case testError

        static private let currentDate = Date()

        var errorDescription: String? {
            switch self {
            case .testError:
                return "Test error description to log " + dateFormater.string(from: LoggerTest.TestError.currentDate)
            }
        }
    }
}

// MARK: - Private

extension LoggerTest {
    private func logMessageTester(level: Logger.Level, message: String) {
        // GIVEN
        var line: Int?

        // WHEN
        switch level {
        case .debug:
            Logger.shared.debug(message: message); line = #line //To test log line
        case .info:
            Logger.shared.info(message: message); line = #line //To test log line
        case .warn:
            Logger.shared.warn(message: message); line = #line //To test log line
        case .error:
            Logger.shared.error(message: message); line = #line //To test log line
        case .errorAndCrash:
            Logger.shared.errorAndCrash(message: message); line = #line //To test log line
        }

        // THEN
        let log = Logger.shared.log
        XCTAssertTrue(log.contains("\(level.rawValue) \(message) (\(#file):\(calledLine(line)) - \(#function))"))
    }

    private func logErrorTester(level: Logger.Level, error: Error) {
        // GIVEN
        var line: Int? //To test logged line

        // WHEN
        switch level {
        case .debug:
            Logger.shared.debug(error: error); line = #line
        case .info:
            Logger.shared.info(error: error); line = #line
        case .warn:
            Logger.shared.warn(error: error); line = #line
        case .error:
            Logger.shared.error(error: error); line = #line
        case .errorAndCrash:
            Logger.shared.errorAndCrash(error: error); line = #line
        }

        // THEN
        let log = Logger.shared.log
        XCTAssertTrue(log.contains("\(level.rawValue) \(error.localizedDescription) (\(#file):\(calledLine(line)) - \(#function))"))
    }

    private var errorDescription: String {
        guard let errorDescription = error.errorDescription else {
            XCTFail()
            return "" // no errorDescription, test failed
        }
        return errorDescription
    }

    func calledLine(_ line: Int?) -> Int {
        guard let line = line else {
            XCTFail()
            return -1 // no line, test failed
        }
        return line
    }
}
