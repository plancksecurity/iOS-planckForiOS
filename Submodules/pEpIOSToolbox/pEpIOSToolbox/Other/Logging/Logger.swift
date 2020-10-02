//
//  Logger.swift
//  pEp
//
//  Created by Dirk Zimmermann on 18.12.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

import CocoaLumberjackSwift

public class Logger {
    public init(subsystem: String = "security.pEp.app.iOS", category: String) {
        self.subsystem = subsystem
        self.category = category
        initLumberjack()
    }

    /// Logs some info helpful when debugging when in DEBUG configuration. Does nothing otherwize.
    public func logDebugInfo() {
        #if DEBUG
        let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        print("documentsDir: \(documentsDir)")        #endif
    }

    /// Use for warnings, anything that might cause trouble.
    /// - Note: Gets persisted, so a later sysinfo on the device will recover it.
    public func warn(function: String = #function,
                     filePath: String = #file,
                     fileLine: Int = #line,
                     _ message: StaticString,
                     _ args: CVarArg...) {
        saveLog(message: message,
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

    /// Use for debug messages only, will not be persisted.
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
    /// - Note: Gets persisted, so a later sysinfo on the device will recover it.
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
        osLog(message: "*** errorAndCrash: \(error)",
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
                              fileLine: Int = #line,
                              message: String) {
        osLog(message: "*** errorAndCrash: \(message)",
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
                              fileLine: Int = #line,
                              _ message: StaticString,
                              _ args: CVarArg...) {
        osLog(message: "*** errorAndCrash: \(message)",
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

    private func initLumberjack() {
        DDLog.add(DDOSLogger.sharedInstance) // Uses os_log

        guard let theDocUrl = createLoggingDirectory() else {
            return
        }

        let fileManager = DDLogFileManagerDefault(logsDirectory: theDocUrl.path)

        let fileLogger: DDFileLogger = DDFileLogger(logFileManager: fileManager)
        fileLogger.rollingFrequency = 60 * 60 * 24 // 24 hours
        fileLogger.logFileManager.maximumNumberOfLogFiles = 7
        DDLog.add(fileLogger)
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

    private func osLog(message: String,
                       severity: Severity,
                       function: String = #function,
                       filePath: String = #file,
                       fileLine: Int = #line,
                       args: [CVarArg]) {
        let interpolatedString = String(format: message, arguments: args)
        let interpolatedMessage = "\(subsystem) \(category) \(filePath):\(fileLine) \(function) \(interpolatedString)"

        switch severity {
        case .debug:
            DDLogDebug(interpolatedMessage)
        case .info:
            DDLogInfo(interpolatedMessage)
        case .warn:
            DDLogWarn(interpolatedMessage)
        case .error:
            DDLogError(interpolatedMessage)
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
    }
}
