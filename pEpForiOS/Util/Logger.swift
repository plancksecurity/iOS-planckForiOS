//
//  Logger.swift
//  pEp
//
//  Created by Dirk Zimmermann on 18.12.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation
import os.log

import MessageModel // For SystemUtils.crash only

/**
 Thin layer over `os_log` or `asl_logger` where not available.
 The fallback to asl is only in effect for iOS 9, and currently
 doesn't appear anywhere visible on that platform.
 */
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

        @available(iOS 10.0, macOS 10.12, tvOS 10.0, watchOS 3.0, *)
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

        /**
         Maps the internal criticality of a log  message into a subsystem of ASL levels.

         ASL has the following:
         * ASL_LEVEL_EMERG
         * ASL_LEVEL_ALERT
         * ASL_LEVEL_CRIT
         * ASL_LEVEL_ERR
         * ASL_LEVEL_WARNING
         * ASL_LEVEL_NOTICE
         * ASL_LEVEL_INFO
         * ASL_LEVEL_DEBUG
         */
        public func aslLevelString() -> String {
            switch self {
            case .default:
                return "ASL_LEVEL_NOTICE"
            case .info:
                return "ASL_LEVEL_INFO"
            case .debug:
                return "ASL_LEVEL_DEBUG"
            case .error:
                return "ASL_LEVEL_ERR"
            case .fault:
                return "ASL_LEVEL_CRIT"
            }
        }
    }

    public static let frontendLogger = Logger(category: "frontend")
    public static let backendLogger = Logger(category: "backend")
    public static let utilLogger = Logger(category: "util")
    public static let htmlParsingLogger = Logger(category: "htmlParsing")
    public static let modelLogger = Logger(category: "model")
    public static let appDelegateLogger = Logger(category: "appDelegate")

    public init(subsystem: String = "security.pEp.app.iOS", category: String) {
        self.subsystem = subsystem
        self.category = category
        if #available(iOS 10.0, macOS 10.12, tvOS 10.0, watchOS 3.0, *) {
            osLogger = OSLog(subsystem: subsystem, category: category)
        } else {
            osLogger = nil
        }
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

        // This will omit the arguments, but it's still matchable
        SystemUtils.crash("\(message)")
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
     Testing only. If you want to test the fallback to ASL logging you may have to call
     this, as all the logging is deferred to a serial queue.
     */
    public func testFlush() {
        if #available(iOS 10.0, macOS 10.12, tvOS 10.0, watchOS 3.0, *) {
            // no sense on these versions
        } else {
            aslLogQueue.sync {
                // nothing
            }
        }
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
        if #available(iOS 10.0, macOS 10.12, tvOS 10.0, watchOS 3.0, *) {
            osLog(message: message,
                  severity: severity,
                  function: function,
                  filePath: filePath,
                  fileLine: fileLine,
                  args: args)
        } else {
            aslLog(message: message,
                   severity: severity,
                   function: function,
                   filePath: filePath,
                   fileLine: fileLine,
                   args: args)
        }
    }

    /**
     - Note: If the number of arguments to the format string exceeds 10,
     the logging doesn't work correctly. Can be easily fixed though, if really needed.
     */
    @available(iOS 10.0, macOS 10.12, tvOS 10.0, watchOS 3.0, *)
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

    private func aslLog(message: StaticString,
                        severity: Severity,
                        function: String = #function,
                        filePath: String = #file,
                        fileLine: Int = #line,
                        args: [CVarArg]) {
        aslLogQueue.async { [weak self] in
            if let theSelf = self {
                let logMessage = asl_new(UInt32(ASL_TYPE_MSG))

                theSelf.checkASLSuccess(asl_set(logMessage, ASL_KEY_SENDER, theSelf.subsystem))

                theSelf.checkASLSuccess(asl_set(logMessage, ASL_KEY_FACILITY, theSelf.category))

                theSelf.checkASLSuccess(asl_set(
                    logMessage,
                    ASL_KEY_MSG,
                    "\(filePath):\(fileLine) \(function): \(message) \(args)"))

                theSelf.checkASLSuccess(asl_set(logMessage, ASL_KEY_LEVEL, "ASL_LEVEL_ERROR"))

                let nowDate = Date()
                let dateString = "\(Int(nowDate.timeIntervalSince1970))"
                theSelf.checkASLSuccess(asl_set(logMessage, ASL_KEY_TIME, dateString))

                theSelf.checkASLSuccess(asl_set(logMessage, ASL_KEY_READ_UID, "-1"))

                theSelf.checkASLSuccess(asl_send(theSelf.consoleLogger(), logMessage))

                asl_free(logMessage)
            }
        }
    }

    private var consoleClient: aslclient?

    private lazy var aslLogQueue = DispatchQueue(label: "security.pEp.asl.log")

    private let sender = "security.pEp.app.iOS"

    private func createConsoleLogger() -> asl_object_t {
        return asl_open(self.sender, subsystem, 0)
    }

    private func consoleLogger() -> aslclient? {
        if consoleClient == nil {
            consoleClient = createConsoleLogger()
        }
        return consoleClient
    }

    deinit {
        if consoleClient != nil {
            asl_free(consoleClient)
        }
    }

    private func checkASLSuccess(_ result: Int32, comment: String = "no comment") {
        if result != 0 {
            print("*** error: \(comment)")
        }
    }
}
