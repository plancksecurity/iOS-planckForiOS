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
    public enum Severity {
        /**
         OSLog.default
         */
        case `default`
        case info
        case debug
        case error
        case fault

        @available(iOS 10.0, macOS 10.12, tvOS 10.0, watchOS 3.0, *)
        public func osLogType() -> OSLogType {
            switch self {
            case .default:
                return .default
            case .info:
                return .info
            case .debug:
                return .debug
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

    public init(subsystem: String, category: String) {
        if #available(iOS 10.0, macOS 10.12, tvOS 10.0, watchOS 3.0, *) {
            self.subsystem = nil
            self.category = nil
            osLogger = OSLog(subsystem: subsystem, category: category)
        } else {
            self.subsystem = subsystem
            self.category = category
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

    private let subsystem: String?
    private let category: String?

    private let osLogger: Any?

    private func saveLog(message: StaticString,
                         severity: Severity,
                         function: String = #function,
                         filePath: String = #file,
                         fileLine: Int = #line,
                         args: [CVarArg]) {
        if #available(iOS 10.0, macOS 10.12, tvOS 10.0, watchOS 3.0, *) {
            let theLog = osLogger as! OSLog
            let theType = severity.osLogType()
            os_log("%@:%d %@:",
                   log: theLog,
                   type: theType,
                   filePath,
                   fileLine,
                   function)
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
                       type: theType)
                os_log(message,
                       log: theLog,
                       type: theType,
                       args)
            }
        } else {
            // TODO: use as_logging
        }
    }
}
