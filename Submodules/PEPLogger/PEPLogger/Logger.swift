//
//  PEPLogger.swift
//  PEPLogger
//
//  Created by Alejandro Gelos on 17/01/2020.
//  Copyright © 2020 Alejandro Gelos. All rights reserved.
//

import Foundation

/// Logs messages to console and a log file that can also be retrieved from this logger.
/// Several log levels are offered. See the docs of the several methods for details.
///
/// The log file is written in the App Group with identifier `group.security.pep.pep4ios`.
/// The log file is replaced with an empty one whenever it reaches max file size.
///
/// Two logging modes are available: normal & verbose.
///
/// Usage Swift: You MUST use the Singleton Logger.shared.
///
/// Usage ObjC: Use the marcos defined in `PEPLogger/PEPLogger.h`.

@objcMembers
public class Logger: NSObject {

    /// Shared instance.
    public static let shared = Logger()
    private override init(){}

    /// Types of logging modes.
    @objc
    public enum Mode: Int {
        case normal, verbose
    }

    /// Logging mode. Default value is normal
    public var mode: Mode = .normal

    /// Log content
    /// Note: This is an expensive (I/O) task. Do not call on the main queue!.
    public var log: String {
        return ""
    }

    private let appGroup = "group.security.pep.pep4ios"
    private let containerFolderName = "PEPLogger"
    private let fileName = "Log"
    private let fileExtension = "txt"

    private var fileFolderURL: URL? {
        let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup)
        return appGroupURL?.appendingPathComponent(containerFolderName, isDirectory: true)
    }
    private var fileURL: URL? {
        let resultURL = fileFolderURL?.appendingPathComponent(fileName, isDirectory: false)
        return resultURL?.appendingPathExtension(fileExtension)
    }

    /// Logs only when build for DEBUG.
    ///
    /// - Parameters:
    ///   - file: You MUST NOT pass anything here. This parameter solely exists to automatically get the file name of the class
    ///   where the method was called.
    ///   - line: You MUST NOT pass anything here. This parameter solely exists to automatically get the line number of the class
    ///   where the method was called.
    ///   - function: You MUST NOT pass anything here. This parameter solely exists to automatically get the name of the
    ///   function where the method was called.
    ///   - message: a message to log.
    public func debug(file: String = #file, line: Int = #line, function: String = #function, message: String) {



        print("pEp[DEBUG] \(message) (\(file):\(line) - \(function))")
    }

    /// Logs only when build for DEBUG.
    ///
    /// - Parameters:
    ///   - file: You MUST NOT pass anything here. This parameter solely exists to automatically get the file name of the class
    ///   where the method was called.
    ///   - line: You MUST NOT pass anything here. This parameter solely exists to automatically get the line number of the class
    ///   where the method was called.
    ///   - function: You MUST NOT pass anything here. This parameter solely exists to automatically get the name of the
    ///   function where the method was called.
    ///   - error: the error to log.
    public func debug(file: String = #file, line: Int = #line, function: String = #function, error: Error) {
        print("** INFO ** ")
    }


    /// Always logs only when build for DEBUG. Logs only in mode `verbose` when build for RELEASE.
    ///
    /// - Parameters:
    ///   - file: You MUST NOT pass anything here. This parameter solely exists to automatically get the file name of the class
    ///   where the method was called.
    ///   - line: You MUST NOT pass anything here. This parameter solely exists to automatically get the line number of the class
    ///   where the method was called.
    ///   - function: You MUST NOT pass anything here. This parameter solely exists to automatically get the name of the
    ///   function where the method was called.
    ///   - message: a message to log.
    public func info(file: String = #file, line: Int = #line, function: String = #function, message: String) {
    }

    /// Always logs only when build for DEBUG. Logs only in mode `verbose` when build for RELEASE.
    ///
    /// - Parameters:
    ///   - file: You MUST NOT pass anything here. This parameter solely exists to automatically get the file name of the class
    ///   where the method was called.
    ///   - line: You MUST NOT pass anything here. This parameter solely exists to automatically get the line number of the class
    ///   where the method was called.
    ///   - function: You MUST NOT pass anything here. This parameter solely exists to automatically get the name of the
    ///   function where the method was called.
    ///   - error: the error to log.
    public func info(file: String = #file, line: Int = #line, function: String = #function, error: Error) {
    }

    /// Always logs.
    ///
    /// - Parameters:
    ///   - file: You MUST NOT pass anything here. This parameter solely exists to automatically get the file name of the class
    ///   where the method was called.
    ///   - line: You MUST NOT pass anything here. This parameter solely exists to automatically get the line number of the class
    ///   where the method was called.
    ///   - function: You MUST NOT pass anything here. This parameter solely exists to automatically get the name of the
    ///   function where the method was called.
    ///   - message: a message to log.
    public func warn(file: String = #file, line: Int = #line, function: String = #function, message: String) {
    }

    /// Always logs.
    ///
    /// - Parameters:
    ///   - file: You MUST NOT pass anything here. This parameter solely exists to automatically get the file name of the class
    ///   where the method was called.
    ///   - line: You MUST NOT pass anything here. This parameter solely exists to automatically get the line number of the class
    ///   where the method was called.
    ///   - function: You MUST NOT pass anything here. This parameter solely exists to automatically get the name of the
    ///   function where the method was called.
    ///   - error: the error to log.
    public func warn(file: String = #file, line: Int = #line, function: String = #function, error: Error) {
    }

    /// Always logs.
    ///
    /// - Parameters:
    ///   - file: You MUST NOT pass anything here. This parameter solely exists to automatically get the file name of the class
    ///   where the method was called.
    ///   - line: You MUST NOT pass anything here. This parameter solely exists to automatically get the line number of the class
    ///   where the method was called.
    ///   - function: You MUST NOT pass anything here. This parameter solely exists to automatically get the name of the
    ///   function where the method was called.
    ///   - message: a message to log.
    public func error(file: String = #file, line: Int = #line, function: String = #function, message: String) {
    }

    /// Always logs.
    ///
    /// - Parameters:
    ///   - file: You MUST NOT pass anything here. This parameter solely exists to automatically get the file name of the class
    ///   where the method was called.
    ///   - line: You MUST NOT pass anything here. This parameter solely exists to automatically get the line number of the class
    ///   where the method was called.
    ///   - function: You MUST NOT pass anything here. This parameter solely exists to automatically get the name of the
    ///   function where the method was called.
    ///   - error: the error to log.
    public func error(file: String = #file, line: Int = #line, function: String = #function, error: Error) {
    }

    /// Always logs. And crash only if build for DEBUG.
    ///
    /// - Parameters:
    ///   - file: You MUST NOT pass anything here. This parameter solely exists to automatically get the file name of the class
    ///   where the method was called.
    ///   - line: You MUST NOT pass anything here. This parameter solely exists to automatically get the line number of the class
    ///   where the method was called.
    ///   - function: You MUST NOT pass anything here. This parameter solely exists to automatically get the name of the
    ///   function where the method was called.
    ///   - message: a message to log.
    public func errorAndCrash(file: String = #file, line: Int = #line, function: String = #function, message: String) {
        try! log(level: .errorAndCrash, file: file, line: String(line), function: function, message: message)
    }

    /// Always logs. And crash only if build for DEBUG.
    ///
    /// - Parameters:
    ///   - file: You MUST NOT pass anything here. This parameter solely exists to automatically get the file name of the class
    ///   where the method was called.
    ///   - line: You MUST NOT pass anything here. This parameter solely exists to automatically get the line number of the class
    ///   where the method was called.
    ///   - function: You MUST NOT pass anything here. This parameter solely exists to automatically get the name of the
    ///   function where the method was called.
    ///   - error: the error to log.
    public func errorAndCrash(file: String = #file, line: Int = #line, function: String = #function, error: Error) {
    }
}

// MARK: - Private

extension Logger {
    private func log(level: Level,
                     file: String,
                     line: String,
                     function: String,
                     message: String) throws {

        guard let fileURL = fileURL else {
            let error = Constants.LoggingError.nilFileURL
            Utils.debugCrash(error.errorDescription)
            throw error
        }
        let data = Utils.newLogDataEntry(level: level,
                                         file: file,
                                         line: line,
                                         function: function,
                                         message: message)

        do {
            // add new entry to log
            let fileHandler = try FileHandle(forWritingTo: fileURL)
            fileHandler.seekToEndOfFile()
            fileHandler.write(data)
            fileHandler.closeFile()
        } catch {
            Utils.debug(error.localizedDescription)
            try createFile(with: data)
        }
    }

    /// Crash in DEGUB if fails
    /// - Parameters:
    ///   - data: data to write
    private func createFile(with data: Data) throws {
        guard let fileFolderURL = fileFolderURL,
            let fileURL = fileURL else {
                let error = Constants.LoggingError.nilFileURL
                Utils.debugCrash(error.errorDescription)
                throw error
        }
        // Create folder if it does not exist
        do {
            try FileManager.default.createDirectory(at: fileFolderURL, withIntermediateDirectories: false)
        } catch {
            print(error.localizedDescription)
            // Folder could exist, continue to create file
        }

        // Override or create log file
        try data.write(to: fileURL)
    }
}

// MARK: - Helping Structures

extension Logger {
    enum Level: String {
        case debug = "pEp[DEBUG]"
        case info = "pEp[INFO]"
        case warn = "pEp[WARN]"
        case error = "pEp[ERROR]"
        case errorAndCrash = "pEp[ERRORandCRASH]"
    }
}
