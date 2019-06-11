//
//  Logger.swift
//  pEp
//
//  Created by Dirk Zimmermann on 18.12.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation
import os.log

/**
 Thin layer over `os_log` where not available.
 */
@available(iOS 10.0, macOS 10.12, tvOS 10.0, watchOS 3.0, *)
public class Logger {
    /**
     Map `os_log` levels.
     */
    public enum Severity {
        /**
         - Note: Not persisted by default, but will be written in case of errors.
         */
        case info

        /**
         - Note: Not persisted by default, but will be written in case of errors.
         */
        case debug

        /**
         This is the lowest priority that gets written to disk by default.
         Used like WARN in this logger.
         */
        case `default`

        case error

        /**
         - Note: As this is referring to inter-process problems, I don't see a use-case
         for iOS.
         */
        case fault

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
            case .fault:
                return .fault
            }
        }
    }

    public init(subsystem: String = "security.pEp.app.iOS", category: String) {
        self.subsystem = subsystem
        self.category = category
        osLogger = OSLog(subsystem: subsystem, category: category)
    }

    /**
     Logs to default.
     */
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

    /**
     os_log doesn't have a warn per se, but default is coming close.
     This is the same as log.
     */
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

    /**
     Logs to info.
     */
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

    /**
     Logs to debug.
     */
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

    /**
     Logs to error.
     */
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

    /**
     Logs to fault.
     */
    public func fault(function: String = #function,
                      filePath: String = #file,
                      fileLine: Int = #line,
                      _ message: StaticString,
                      _ args: CVarArg...) {
        saveLog(message: message,
                severity: .fault,
                function: function,
                filePath: filePath,
                fileLine: fileLine,
                args: args)
    }

    public func errorAndCrash(function: String = #function,
                              filePath: String = #file,
                              fileLine: Int = #line,
                              error: Error) {
        os_log("*** errorAndCrash: %@ (%@:%d %@)",
               log: osLogger as! OSLog,
               type: .fault,
               error as CVarArg,
               filePath,
               fileLine,
               function)

        SystemUtils.crash("*** errorAndCrash: \(error) (\(filePath):\(fileLine) \(function))")
    }

    public func errorAndCrash(function: String = #function,
                              filePath: String = #file,
                              fileLine: Int = #line,
                              message: String) {
        os_log("*** errorAndCrash: %@ (%@:%d %@)",
               log: osLogger as! OSLog,
               type: .fault,
               message,
               filePath,
               fileLine,
               function)

        SystemUtils.crash("*** errorAndCrash: \(message) (\(filePath):\(fileLine) \(function))")
    }

    public func errorAndCrash(function: String = #function,
                              filePath: String = #file,
                              fileLine: Int = #line,
                              _ message: StaticString,
                              _ args: CVarArg...) {
        saveLog(message: message,
                severity: .fault,
                function: function,
                filePath: filePath,
                fileLine: fileLine,
                args: args)

        SystemUtils.crash("*** errorAndCrash: \(message) (\(filePath):\(fileLine) \(function))")
    }

    /**
     Logs an error.
     */
    public func log(function: String = #function,
                    filePath: String = #file,
                    fileLine: Int = #line,
                    error: Error) {
        // Error is not supported by "%@", because it doesn't conform to CVArg
        // and CVArg is only meant for internal types.
        // An alternative would be to use localizedDescription(),
        // but if they are indeed localized you end up with international
        // log messages.
        // So we wrap it into an NSError which does suppord CVArg.
        let nsErr = NSError(domain: subsystem, code: 0, userInfo: [NSUnderlyingErrorKey: error])

        saveLog(message: "%@",
                severity: .default,
                function: function,
                filePath: filePath,
                fileLine: fileLine,
                args: [nsErr])
    }

    /**
     Since this kind of logging is used so often in the codebase, it has its
     own method.
     */
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

    /**
     - Note: Wrapping `os_log` causes all kinds of problems, so until
        there is an official version of it that accepts `[CVarArg]` (os_logv?),
        interpolation is handled by us.
     */
    private func osLog(message: String,
                       severity: Severity,
                       function: String = #function,
                       filePath: String = #file,
                       fileLine: Int = #line,
                       args: [CVarArg]) {
        var shouldLog = false

        #if DEBUG
        shouldLog = true
        #else
        if severity == .error || severity == .fault || severity == .default {
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
}
