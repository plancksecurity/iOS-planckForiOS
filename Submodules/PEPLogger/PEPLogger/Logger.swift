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
    private let fileName = "Log.txt"

    private var fileFolderURL: URL? {
        let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup)
        return appGroupURL?.appendingPathComponent(containerFolderName)
    }
    private var fileURL: URL? {
        return fileFolderURL?.appendingPathComponent(fileName)
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
        log(level: .errorAndCrash, file: file, line: String(line), function: function, message: message)
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
    private func log(level: Level, file: String, line: String, function: String, message: String) {
        guard let filePath = fileURL?.absoluteString else {
            debugCrash("Fail to get file URL absoluteString")
            return
        }

        let data = dataToLog(level: level,
                             file: file,
                             line: line,
                             function: function,
                             message: message)

        if !FileManager.default.fileExists(atPath: filePath) {
            createFile(atPath: filePath, data: data)
        } else {
            guard let fileHandler = FileHandle(forWritingAtPath: filePath) else {
                debugCrash("Fail to write to file URL absoluteString")
                return
            }
            fileHandler.seekToEndOfFile()
            fileHandler.write(data)
            fileHandler.closeFile()
        }
    }

    private func textToLog(level: Level,
                           file: String,
                           line: String,
                           function: String,
                           message: String) -> String {

        return "\(level.rawValue) \(message) (\(file):\(line) - \(function))"
    }

    private func dataToLog(level: Level,
                           file: String,
                           line: String,
                           function: String,
                           message: String) -> Data {

        let text = textToLog(level: level,
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


    /// Crash in DEGUB if fails
    /// - Parameters:
    ///   - atPath: file path
    ///   - data: data to write
    private func createFile(atPath: String, data: Data) {
        guard let fileFolderPath = fileFolderURL?.absoluteString else {
            debugCrash("Fail to get fileFolderPath")
            return
        }
        do {
            try FileManager.default.createDirectory(atPath: fileFolderPath,
                                                    withIntermediateDirectories: true)
        }
        catch {
            debugCrash(error.localizedDescription)
            return
        }
        if FileManager.default.createFile(atPath: atPath, contents: data) {
            return
        } else {
            debugCrash("Fail to create log file")
            return
        }
    }


    /// Crash in DEBUG only
    /// - Parameter message: crash information
    private func debugCrash(_ message: String) {
        #if DEBUG
        fatalError("pEpLogger: \(message)")
        #endif
    }


    //            guard let fileURL = fileURL else {
    //                #if DEBUG
    //                fatalError("PEPLogger: Fail to get fileURL")
    //                #endif
    //                return
    //            }
    //            do {
    //                try textToLog.write(to: fileURL, atomically: true, encoding: .utf8)
    //            }
    //            catch {
    //                #if DEBUG
    //                fatalError("PEPLogger: Fail to create log file")
    //                #endif
    //            }
    //        }

    //        "pEp[DEBUG] \(message) (\(file):\(line) - \(function))".write(to: <#T##URL#>, atomically: <#T##Bool#>, encoding: <#T##String.Encoding#>)


    private func log(level: Level, error: Error) {

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
