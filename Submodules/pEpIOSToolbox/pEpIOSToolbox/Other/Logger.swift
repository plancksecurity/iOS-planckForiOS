//
//  Logger.swift
//  pEp
//
//  Created by Dirk Zimmermann on 18.12.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation
import os.log

public class Logger {
    public init(subsystem: String = "security.pEp.app.iOS", category: String) {
        self.subsystem = subsystem
        self.category = category
        osLogger = OSLog(subsystem: subsystem, category: category)
    }

    /// Use for messages that are at least important enough to get persisted
    /// even in a release build.
    public func log(function: String = #function,
                    filePath: String = #file,
                    fileLine: Int = #line,
                    _ message: StaticString,
                    _ args: CVarArg...) {
        saveLog(message: message,
                severity: .default,
                function: function,
                filePath: filePath,
                fileLine: fileLine,
                args: args)
    }

    /// Use for warnings, anything that might cause trouble.
    public func warn(function: String = #function,
                     filePath: String = #file,
                     fileLine: Int = #line,
                     _ message: StaticString,
                     _ args: CVarArg...) {
        saveLog(message: message,
                severity: .default,
                function: function,
                filePath: filePath,
                fileLine: fileLine,
                args: args)
    }

    /// Will not be logged in a release build, and even in a debug build will
    /// only get persisted if an error later occurrs.
    public func info(function: String = #function,
                     filePath: String = #file,
                     fileLine: Int = #line,
                     _ message: StaticString,
                     _ args: CVarArg...) {
        saveLog(message: message,
                severity: .info,
                function: function,
                filePath: filePath,
                fileLine: fileLine,
                args: args)
    }

    /// Will not be logged in a release build, and even in a debug build will
    /// only get persisted if an error later occurrs. Use for messages
    /// that are needed during debugging of a feature, if it's not possible
    /// to do that in the debugger itself.
    public func debug(function: String = #function,
                      filePath: String = #file,
                      fileLine: Int = #line,
                      _ message: StaticString,
                      _ args: CVarArg...) {
        saveLog(message: message,
                severity: .debug,
                function: function,
                filePath: filePath,
                fileLine: fileLine,
                args: args)
    }

    /// Use this for indicating error conditions.
    public func error(function: String = #function,
                      filePath: String = #file,
                      fileLine: Int = #line,
                      _ message: StaticString,
                      _ args: CVarArg...) {
        saveLog(message: message,
                severity: .error,
                function: function,
                filePath: filePath,
                fileLine: fileLine,
                args: args)
    }

    /// Logs an error and crashes in a debug build, continues to run in a release build.
    public func errorAndCrash(function: String = #function,
                              filePath: String = #file,
                              fileLine: Int = #line,
                              error: Error) {
        os_log("*** errorAndCrash: %@ (%@:%d %@)",
               log: osLogger as! OSLog,
               type: .error,
               "\(error)",
               filePath,
               fileLine,
               function)

        SystemUtils.crash("*** errorAndCrash: \(error) (\(filePath):\(fileLine) \(function))")
    }

    /// Logs an error message and crashes in a debug build, continues to run in a release build.
    public func errorAndCrash(function: String = #function,
                              filePath: String = #file,
                              fileLine: Int = #line,
                              message: String) {
        os_log("*** errorAndCrash: %@ (%@:%d %@)",
               log: osLogger as! OSLog,
               type: .error,
               message,
               filePath,
               fileLine,
               function)

        SystemUtils.crash("*** errorAndCrash: \(message) (\(filePath):\(fileLine) \(function))")
    }

    /// Logs an error message (with parameters) and crashes in a debug build,
    /// continues to run in a release build.
    public func errorAndCrash(function: String = #function,
                              filePath: String = #file,
                              fileLine: Int = #line,
                              _ message: StaticString,
                              _ args: CVarArg...) {
        osLog(message: "*** errorAndCrash: \(message)",
            severity: .error,
            function: function,
            filePath: filePath,
            fileLine: fileLine,
            args: args)

        SystemUtils.crash("*** errorAndCrash: \(message) (\(filePath):\(fileLine) \(function))")
    }

    /// Logs an error.
    public func log(function: String = #function,
                    filePath: String = #file,
                    fileLine: Int = #line,
                    error theError: Error) {
        error(function: function,
              filePath: filePath,
              fileLine: fileLine,
              "%@",
              "\(theError)")
    }

    /// Since this kind of logging is used so often in the codebase, it has its
    /// own method.
    public func lostMySelf() {
        errorAndCrash("Lost MySelf")
    }

    private let subsystem: String
    private let category: String

    private let osLogger: Any?

    private func saveLog(message: StaticString,
                         severity: Severity,
                         function: String = #function,
                         filePath: String = #file,
                         fileLine: Int = #line,
                         args: [CVarArg]) {
        osLog(message: "\(message)",
              severity: severity,
              function: function,
              filePath: filePath,
              fileLine: fileLine,
              args: args)
    }

    /// - Note: Wrapping `os_log` causes all kinds of problems, so until
    ///   there is an official version of it that accepts `[CVarArg]` (os_logv?),
    ///   interpolation is handled by us, under certain conditions.
    private func osLog(message: String,
                       severity: Severity,
                       function: String = #function,
                       filePath: String = #file,
                       fileLine: Int = #line,
                       args: [CVarArg]) {
        var shouldLog = false

        #if DEBUG
        // in a debug build, log everything
        shouldLog = true
        #else
        // in a release, only log errors and warnings
        if severity == .error || severity == .default {
            shouldLog = true
        } else {
            shouldLog = false
        }
        #endif

        if shouldLog {
            let theLog = osLogger as! OSLog
            let theType = severity.osLogType()

            let ourString = String(format: "\(message)", arguments: args)

            os_log("%@ (%@:%d %@)",
                   log: theLog,
                   type: theType,
                   ourString,
                   filePath,
                   fileLine,
                   function)
        }
    }

    /// The supported log levels, used internally.
    private enum Severity {
        /// - Note: Not persisted by default, but will be written in case of errors.
        case info

        /// - Note: Not persisted by default, but will be written in case of errors.
        case debug

        /// Both normal log calls and warn are mapped internally to this.
        /// - Note: Gets persisted by default.
        case `default`

        /// Indicates an error.
        /// - Note: Gets persisted.
        case error

        /// Mapping to `OSLogType`.
        public func osLogType() -> OSLogType {
            switch self {
            case .info:
                return .info
            case .debug:
                return .debug
            case .default:
                return .default
            case .error:
                return .error
            }
        }
    }
}
