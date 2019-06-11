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
                              _ message: StaticString,
                              _ args: CVarArg...) {
        saveLog(message: message,
                severity: .fault,
                function: function,
                filePath: filePath,
                fileLine: fileLine,
                args: args)

        SystemUtils.crash("\(filePath):\(function):\(fileLine) - \(message)")
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

        saveLog(message: "%{public}@",
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
        osLog(message: message,
              severity: severity,
              function: function,
              filePath: filePath,
              fileLine: fileLine,
              args: args)
    }

    /**
     - Note: If the number of arguments to the format string exceeds 10,
     the logging doesn't work correctly. Can be easily fixed though, if really needed.
     */
    private func osLog(message: StaticString,
                       severity: Severity,
                       function: String = #function,
                       filePath: String = #file,
                       fileLine: Int = #line,
                       args: [CVarArg]) {
        let theLog = osLogger as! OSLog
        let theType = severity.osLogType()

        // I haven't found a way of injecting `function` etc. into the original message for
        // just one call to `os_log`, so the 'position' is logged on a separate line.
        os_log("%@:%d %@:",
               log: theLog,
               type: theType,
               filePath,
               fileLine,
               function)

        // We have to expand the array of arguments into positional ones.
        // There is no attempt of trying to format the string on our side
        // in order to make use of `os_log`'s fast 'offline' formatting
        // (that is, the work is delayed until actual log display).
        switch args.count {
        case 0:
            os_log(message,
                   log: theLog,
                   type: theType)
        case 1:
            os_log(message,
                   log: theLog,
                   type: theType,
                   args[0])
        case 2:
            os_log(message,
                   log: theLog,
                   type: theType,
                   args[0], args[1])
        case 3:
            os_log(message,
                   log: theLog,
                   type: theType,
                   args[0], args[1], args[2])
        case 4:
            os_log(message,
                   log: theLog,
                   type: theType,
                   args[0], args[1], args[2], args[3])
        case 5:
            os_log(message,
                   log: theLog,
                   type: theType,
                   args[0], args[1], args[2], args[3], args[4])
        case 6:
            os_log(message,
                   log: theLog,
                   type: theType,
                   args[0], args[1], args[2], args[3], args[4], args[5])
        case 7:
            os_log(message,
                   log: theLog,
                   type: theType,
                   args[0], args[1], args[2], args[3], args[4], args[5], args[6])
        case 8:
            os_log(message,
                   log: theLog,
                   type: theType,
                   args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7])
        case 9:
            os_log(message,
                   log: theLog,
                   type: theType,
                   args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7],
                   args[8])
        case 10:
            os_log(message,
                   log: theLog,
                   type: theType,
                   args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7],
                   args[8], args[9])
        default:
            os_log("Using more than 10 parameters",
                   log: theLog,
                   type: .error)
            os_log(message,
                   log: theLog,
                   type: theType,
                   args)
        }
    }
}
