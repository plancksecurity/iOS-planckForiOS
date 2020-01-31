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
    static func debugCrash(_ message: String) {
        #if DEBUG
        fatalError("pEpLogger: \(message)")
        #endif
    }

    // New text to log
    static func newLogEntry(level: Logger.Level,
                            file: String,
                            line: String,
                            function: String,
                            message: String) -> String {

        return "\(level.rawValue) \(message) (\(file):\(line) - \(function))"
    }

    // New data to log
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
