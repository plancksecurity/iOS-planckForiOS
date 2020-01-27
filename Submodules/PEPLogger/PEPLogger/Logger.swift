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
    @objc public enum Mode: Int {
        case normal, verbose
    }

    /// Logging mode. Default value is normal
    public var mode: Mode = .normal

    /// Log content
    /// Note: This is an expensive (I/O) task. Do not call on the main queue!.
    public var log: String {
        return ""
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

//private enum LogType {
//    case log, debug, info, warn, error, errorAndCrash
//}
