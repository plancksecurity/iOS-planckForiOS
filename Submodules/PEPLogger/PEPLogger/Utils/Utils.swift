//
//  Utils.swift
//  PEPLogger
//
//  Created by Alejandro Gelos on 31/01/2020.
//  Copyright © 2020 Alejandro Gelos. All rights reserved.
//

import Foundation

struct Utils {
    /// Crash in DEBUG only
    /// - Parameter message: crash information
    static func debugCrash(_ message: String?) {
        #if DEBUG
        let message = message ?? "Unknown error."
        fatalError("pEpLogger: \(message)")
        #endif
    }

    /// Print in console
    /// - Parameter message: text to print
    static func debug(_ message: String?) {
        #if DEBUG
        let message = message ?? "Unknown debug."
        print("pEpLogger: \(message)")
        #endif
    }

    /// Generate a new log entry
    /// - Parameters:
    ///   - level: logger level
    ///   - file: name of the class
    ///   - line: line of the class
    ///   - function: name of the funtion
    ///   - message: a message to log
    static func newLogEntry(level: Logger.Level,
                            file: String,
                            line: String,
                            function: String,
                            message: String) -> String {

        return "\n\(level.rawValue) \(message) (\(file):\(line) - \(function))"
    }

    /// Generate a new log entry
    /// - Parameters:
    ///   - level: logger level
    ///   - file: name of the class
    ///   - line: line of the class
    ///   - function: name of the funtion
    ///   - message: a message to log
    static func newLogDataEntry(level: Logger.Level,
                                file: String,
                                line: String,
                                function: String,
                                message: String) -> Data {

        let text = newLogEntry(level: level,
                               file: file,
                               line: line,
                               function: function,
                               message: message)
        guard let data = text.data(using: .utf8) else {
            debugCrash("Fail to conver String to Data")
            return Data()
        }
        return data
    }
}
