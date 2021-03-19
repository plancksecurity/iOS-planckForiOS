//
//  Logger.swift
//  pEp
//
//  Created by Dirk Zimmermann on 18.12.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

#if canImport(CocoaLumberjackSwift)
import CocoaLumberjackSwift
#elseif canImport(CocoaLumberjack_macOS)
import CocoaLumberjack_macOS
#elseif canImport(CocoaLumberjack)
import CocoaLumberjack
#endif

@objc public class Logger: NSObject {
    public var verboseLoggingEnabled: Bool = false

    public override init() {
        super.init()
        if #available(iOS 10, macOS 10.12, *) {
            initLumberjack()
        } else {
            // Our logging requires os_log, which is available in since iOS10 and macOS 10.12.
            // No fallback available, sorry ...
        }
    }

    /// Logs some info helpful when debugging when in DEBUG configuration. Does nothing otherwize.
    public func logDebugInfo() {
        #if DEBUG
        let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        print("documentsDir: \(documentsDir)")
        #endif
    }

    /// Use for warnings, anything that might cause trouble.
    /// - Note: Gets persisted, so a later sysinfo on the device will recover it.
    public func warn(function: String = #function,
                     filePath: String = #file,
                     fileLine: UInt = #line,
                     _ message: StaticString,
                     _ args: CVarArg...) {
        saveLog(message: "\(message)",
                severity: .warn,
                function: function,
                filePath: filePath,
                fileLine: fileLine,
                args: args)
    }

    /// Will not be logged in a release build at all.
    /// - Note: Even in a debug build,
    ///     does not get persisted by default (unless an error follows closely),
    ///     so don't expect to find this in a sysinfo log.
    public func info(function: String = #function,
                     filePath: String = #file,
                     fileLine: UInt = #line,
                     _ message: StaticString,
                     _ args: CVarArg...) {
        saveLog(message: "\(message)",
                severity: .info,
                function: function,
                filePath: filePath,
                fileLine: fileLine,
                args: args)
    }

    /// Use for debug messages only, will not be persisted.
    public func debug(function: String = #function,
                      filePath: String = #file,
                      fileLine: UInt = #line,
                      _ message: StaticString,
                      _ args: CVarArg...) {
        saveLog(message: "\(message)",
                severity: .debug,
                function: function,
                filePath: filePath,
                fileLine: fileLine,
                args: args)
    }

    /// Use this for indicating error conditions.
    /// - Note: Gets persisted, so a later sysinfo on the device will recover it.
    public func error(function: String = #function,
                      filePath: String = #file,
                      fileLine: UInt = #line,
                      _ message: StaticString,
                      _ args: CVarArg...) {
        saveLog(message: "\(message)",
                severity: .error,
                function: function,
                filePath: filePath,
                fileLine: fileLine,
                args: args)
    }

    /// Logs an error and crashes in a debug build, continues to run in a release build.
    public func errorAndCrash(function: String = #function,
                              filePath: String = #file,
                              fileLine: UInt = #line,
                              error: Error) {
        interpolateAndLog(message: "*** errorAndCrash: \(error)",
                          severity: .error,
                          function: function,
                          filePath: filePath,
                          fileLine: fileLine,
                          args: [])

        SystemUtils.crash("*** errorAndCrash: \(error) (\(filePath):\(fileLine) \(function))")
    }

    /// Logs an error message and crashes in a debug build, continues to run in a release build.
    public func errorAndCrash(function: String = #function,
                              filePath: String = #file,
                              fileLine: UInt = #line,
                              message: String) {
        interpolateAndLog(message: "*** errorAndCrash: \(message)",
                          severity: .error,
                          function: function,
                          filePath: filePath,
                          fileLine: fileLine,
                          args: [])

        SystemUtils.crash("*** errorAndCrash: \(message) (\(filePath):\(fileLine) \(function))")
    }

    /// Logs an error message (with parameters) and crashes in a debug build,
    /// continues to run in a release build.
    public func errorAndCrash(function: String = #function,
                              filePath: String = #file,
                              fileLine: UInt = #line,
                              _ message: StaticString,
                              _ args: CVarArg...) {
        interpolateAndLog(message: "*** errorAndCrash: \(message)",
                          severity: .error,
                          function: function,
                          filePath: filePath,
                          fileLine: fileLine,
                          args: args)

        let ourString = String(format: "\(message)", arguments: args)
        SystemUtils.crash("*** errorAndCrash: \(ourString) (\(filePath):\(fileLine) \(function))")
    }

    /// Logs an error.
    public func log(function: String = #function,
                    filePath: String = #file,
                    fileLine: UInt = #line,
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

    @objc public func logInfo(message: String,
                              function: String = #function,
                              filePath: String = #file,
                              fileLine: UInt = #line) {
        saveLog(message: message,
                severity: .info,
                function: function,
                filePath: filePath,
                fileLine: fileLine,
                args: [])
    }

    @objc public func logError(message: String,
                               function: String = #function,
                               filePath: String = #file,
                               fileLine: UInt = #line) {
        saveLog(message: message,
                severity: .error,
                function: function,
                filePath: filePath,
                fileLine: fileLine,
                args: [])
    }

    @objc public func logErrorAndCrash(message: String,
                                       function: String = #function,
                                       filePath: String = #file,
                                       fileLine: UInt = #line) {
        saveLog(message: message,
                severity: .error,
                function: function,
                filePath: filePath,
                fileLine: fileLine,
                args: [])
        SystemUtils.crash("*** errorAndCrash: \(message) (\(filePath):\(fileLine) \(function))")
    }

    @objc public func logWarn(message: String,
                              function: String = #function,
                              filePath: String = #file,
                              fileLine: UInt = #line) {
        saveLog(message: message,
                severity: .warn,
                function: function,
                filePath: filePath,
                fileLine: fileLine,
                args: [])
    }

    /// Gets the latest log entries as a string.
    ///
    /// Can be used for polling for log contents.
    public func getLatestLogString() -> String {
        guard let filePath = fileLogger?.currentLogFileInfo?.filePath else {
            return ""
        }
        do {
            return try String(contentsOfFile: filePath)
        } catch {
            log(error: error)
            return ""
        }
    }

    // MARK: -- Private

    private var fileLogger: DDFileLogger?

    @available(iOS 10, *)
    @available(OSX 10.12, *)
    private func initLumberjack() {
        DDLog.add(DDOSLogger.sharedInstance) // Uses os_log

        guard let theDocUrl = createLoggingDirectory() else {
            return
        }

        let fileManager = DDLogFileManagerDefault(logsDirectory: theDocUrl.path)

        let theFileLogger: DDFileLogger = DDFileLogger(logFileManager: fileManager)
        theFileLogger.rollingFrequency = 60 * 60 * 24 // 24 hours
        theFileLogger.logFileManager.maximumNumberOfLogFiles = 7
        DDLog.add(theFileLogger)

        self.fileLogger = theFileLogger
    }

    private func getLoggingDirectory() -> URL? {
        let documentsUrl = FileManager.default.urls(for: .documentDirectory,
                                                    in: .userDomainMask).first
        guard var theDocUrl = documentsUrl else {
            return nil
        }

        theDocUrl.appendPathComponent("logs")

        return theDocUrl
    }

    private func createLoggingDirectory() -> URL? {
        guard let theDocUrl = getLoggingDirectory() else {
            return nil
        }

        do {
            try FileManager.default.createDirectory(at: theDocUrl,
                                                    withIntermediateDirectories: true,
                                                    attributes: nil)
            return theDocUrl
        } catch {
            errorAndCrash("Could not create the logging directory")
        }

        return nil
    }

    private func saveLog(message: String,
                         severity: Severity,
                         function: String = #function,
                         filePath: String = #file,
                         fileLine: UInt = #line,
                         args: [CVarArg]) {
        if (severity.shouldBeLoggedIfNotDebug(verbose: verboseLoggingEnabled)) {
            interpolateAndLog(message: message,
                              severity: severity,
                              function: function,
                              filePath: filePath,
                              fileLine: fileLine,
                              args: args)
        }
    }

    private func interpolateAndLog(message: String,
                                   severity: Severity,
                                   function: String = #function,
                                   filePath: String = #file,
                                   fileLine: UInt = #line,
                                   args: [CVarArg]) {

        // Note that we interpolate _both_ the args _and_ the location info ourselves,
        // instead of letting the logging framework handle it.
        // This is necessary to be compatible with ObjC, who doesn't know about StaticString,
        // while lumberjack only accepts StaticString in its (swift) interface.
        // Alternatively, we could move this file into ObjC world, and use
        // only the ObjC version of lumberjack.
        let interpolatedString = String(format: message, arguments: args)
        let interpolatedMessage = "\(filePath):\(fileLine) \(function) \(interpolatedString)"

        if #available(iOS 10, macOS 10.12, *) {
        func ddlogMessage(for severty: Severity) -> DDLogMessage {
            var logLevel = DDLogLevel.verbose
            var logFlag = DDLogFlag.verbose
            switch severty {
            case .info:
                logFlag = DDLogFlag.info
                logLevel = DDLogLevel.info
            case .debug:
                logFlag = DDLogFlag.debug
                logLevel = DDLogLevel.debug
            case .warn:
                logFlag = DDLogFlag.warning
                logLevel = DDLogLevel.warning
            case .error:
                logFlag = DDLogFlag.error
                logLevel = DDLogLevel.error
            }
            return DDLogMessage(message: interpolatedMessage,
                                level: logLevel,
                                flag: logFlag,
                                context: 0,
                                file: filePath,
                                function: function,
                                line: fileLine,
                                tag: nil,
                                options: DDLogMessageOptions.dontCopyMessage,
                                timestamp: nil)
        }

        switch severity {
        case .debug:
            DDLog.sharedInstance.log(asynchronous: false, message: ddlogMessage(for: .debug))
        case .info:
            DDLog.sharedInstance.log(asynchronous: false, message: ddlogMessage(for: .info))
        case .warn:
            DDLog.sharedInstance.log(asynchronous: false, message: ddlogMessage(for: .warn))
        case .error:
            DDLog.sharedInstance.log(asynchronous: false, message: ddlogMessage(for: .error))
        }
        } else {
            // Our logging requires os_log, which is available in since iOS10 and macOS 10.12.
            NSLog(interpolatedString)
        }
    }

    /// The supported log levels, used internally.
    private enum Severity {
        /// - Note: Not persisted by default, but will be written in case of errors.
        case info

        /// - Note: Not persisted by default, but will be written in case of errors.
        case debug

        /// - Note: Gets persisted by default.
        case warn

        /// Indicates an error.
        /// - Note: Gets persisted.
        case error

        /// Determines if this severity should lead to logging,
        /// depending on the provided verbose flag, and if DEBUG is set or not.
        /// - Returns: `true` when this severity should lead to logging, `false` otherwise
        func shouldBeLoggedIfNotDebug(verbose: Bool) -> Bool {
            #if DEBUG
            // Log everything in DEBUG
            return true
            #else
            if verbose {
                // In !DEBUG, log if verbose is ON.
                return true
            } else {
                // In !DEBUG, !verbose, log depending on severity
                switch self {
                case .info:
                    return false
                case .debug:
                    return false
                case .warn:
                    return true
                case .error:
                    return true
                }
            }
            #endif
        }
    }
}
