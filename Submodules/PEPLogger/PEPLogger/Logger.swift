//
//  PEPLogger.swift
//  PEPLogger
//
//  Created by Alejandro Gelos on 17/01/2020.
//  Copyright © 2020 Alejandro Gelos. All rights reserved.
//

import Foundation

/// This is a logging API  for capturing messaging across all levels of the system.
/// There are several log levels employed by this logger, which correspond to the different types of messages your app may need to
/// capture, and define when messages are store in the device (in a text file), shown in console or both.
///
/// If the text file stored in the device reach the maximum size, another text file will be created to continue logging.
/// A literal is the source code representation of a value of a type (in this case String and Ints). And will be autocompleted with the correct
/// information, from where the log was trigger. Do not pass any parameter there, unless you need it.
///
/// Note: This API was created to have all the log in one text file. So the end user  can easily share captured logs from the text file, to
/// the developer team for debug purpose. Example with a button in Settings.
///
/// How to use: go to your Target, Frameworks, Libraries and add PEPLogger.
///
/// From  Objective-C: #import "PEPLogger/PEPLogger.h"
/// Use the macros in LConstats.h. Macros will call Logger.Swift functons with the correct literals values.
/// Example: LOG_DEBUG_WITH_MESSAGE(@"Some debuging information");
/// Example 2: LOG_ERROR_AND_CRASH_WITH_ERROR(error); //where error is an NSError
///
/// From Swift: import PEPLogger
/// Then use Logger Singleton functions to log events
/// Example: Logger.share.debug(message: "Some debuging information")
@objcMembers
public class Logger: NSObject {

    /// Logger Singleton.
    public static let share = Logger()

    private override init(){}

    /// Debug-level messages are intended to be use in a development environment and not in shipping software.
    /// Debug-level messages are only shown in console when debuging but not in Release.
    /// Note that nothing will be store in the device.
    ///
    /// - Parameters:
    ///   - file: literal String, representing the name of the file where the log was trigger. (autocompleted parameted)
    ///   - line: literal Int, representing the line number where the log was trigger. (autocompleted parameted)
    ///   - function: literal String, representing the name of the declaration where the log was trigger. (autocompleted parameted)
    ///   - message: optional String message that helps to understand or gives more details about the log. If nil message, empty
    ///   message information will be added on the log.
    public func debug(file: String = #file, line: Int = #line, function: String = #function, message: String? = nil) {

    }

    /// Debug-level messages are intended to be use in a development environment and not in shipping software.
    /// Debug-level messages are only shown in console when debuging but not in Release.
    /// Note that nothing will be store in the device.
    ///
    /// - Parameters:
    ///   - file: literal String, representing the name of the file where the log was trigger. (autocompleted parameted)
    ///   - line: literal Int, representing the line number where the log was trigger. (autocompleted parameted)
    ///   - function: literal String, representing the name of the declaration where the log was trigger. (autocompleted parameted)
    ///   - error: optional Error that helps to understand what went wrong. This is the actual error that we get from the app (if any).
    ///   If nil error is pass, empty error information will be added on the log.
    public func debug(file: String = #file, line: Int = #line, function: String = #function, error: Error? = nil) {
    }

    /// Info-level messages are intended for capturing information that may be helpful, but isn’t essential, for troubleshooting errors.
    /// Info-level messages are store in the device. And also shown in console when debuging but not in Release.
    ///
    /// - Parameters:
    ///   - file: literal String, representing the name of the file where the log was trigger. (autocompleted parameted)
    ///   - line: literal Int, representing the line number where the log was trigger. (autocompleted parameted)
    ///   - function: literal String, representing the name of the declaration where the log was trigger. (autocompleted parameted)
    ///   - message: optional String message that helps to understand or gives more details about the log. If nil message, empty
    ///   message information will be added on the log. Make sure to add the actual error at least.
    public func info(file: String = #file, line: Int = #line, function: String = #function, message: String? = nil) {
    }

    /// Info-level messages are intended for capturing information that may be helpful, but isn’t essential, for troubleshooting errors.
    /// Info-level messages are store in the device. And also shown in console when debuging but not in Release.
    ///
    /// - Parameters:
    ///   - file: literal String, representing the name of the file where the log was trigger. (autocompleted parameted)
    ///   - line: literal Int, representing the line number where the log was trigger. (autocompleted parameted)
    ///   - function: literal String, representing the name of the declaration where the log was trigger. (autocompleted parameted)
    ///   - error: optional Error that helps to understand what went wrong. This is the actual error that we get from the app (if any).
    ///   If nil error is pass, empty error information will be added on the log.
    public func info(file: String = #file, line: Int = #line, function: String = #function, error: Error? = nil) {
    }

    /// Warn-level messages are intended for capturing information about things that might result a failure.
    /// Warn-level messages are shown in console and  also store in the device.
    ///
    /// - Parameters:
    ///   - file: literal String, representing the name of the file where the log was trigger. (autocompleted parameted)
    ///   - line: literal Int, representing the line number where the log was trigger. (autocompleted parameted)
    ///   - function: literal String, representing the name of the declaration where the log was trigger. (autocompleted parameted)
    ///   - message: optional String message that helps to understand or gives more details about the log. If nil message, empty
    ///   message information will be added on the log. Make sure to add the actual error at least.
    public func warn(file: String = #file, line: Int = #line, function: String = #function, message: String? = nil) {
    }

    /// Warn-level messages are intended for capturing information about things that might result a failure.
    /// Warn-level messages are shown in console and  also store in the device.
    ///
    /// - Parameters:
    ///   - file: literal String, representing the name of the file where the log was trigger. (autocompleted parameted)
    ///   - line: literal Int, representing the line number where the log was trigger. (autocompleted parameted)
    ///   - function: literal String, representing the name of the declaration where the log was trigger. (autocompleted parameted)
    ///   - error: optional Error that helps to understand what went wrong. This is the actual error that we get from the app (if any).
    ///   If nil error is pass, empty error information will be added on the log.
    public func warn(file: String = #file, line: Int = #line, function: String = #function, error: Error? = nil) {
    }



    /// Error-level messages are intended for reporting process-level errors. But not critical errors that lead to unknown states of the app.
    /// Error-level messages are always store in the device and shown in console. And will NOT crash the app, just log the error.
    ///
    /// - Parameters:
    ///   - file: literal String, representing the name of the file where the log was trigger. (autocompleted parameted)
    ///   - line: literal Int, representing the line number where the log was trigger. (autocompleted parameted)
    ///   - function: literal String, representing the name of the declaration where the log was trigger. (autocompleted parameted)
    ///   - message: optional String message that helps to understand or gives more details about the log. If nil message, empty
    ///   message information will be added on the log. Make sure to add the actual error at least.
    public func error(file: String = #file, line: Int = #line, function: String = #function, message: String? = nil) {
    }

    /// Error-level messages are intended for reporting process-level errors. But not critical errors that lead to unknown states of the app.
    /// Error-level messages are always store in the device and shown in console. And will NOT crash the app, just log the error.
    ///
    /// - Parameters:
    ///   - file: literal String, representing the name of the file where the log was trigger. (autocompleted parameted)
    ///   - line: literal Int, representing the line number where the log was trigger. (autocompleted parameted)
    ///   - function: literal String, representing the name of the declaration where the log was trigger. (autocompleted parameted)
    ///   - error: optional Error that helps to understand what went wrong. This is the actual error that we get from the app (if any).
    ///   If nil error is pass, empty error information will be added on the log.
    public func error(file: String = #file, line: Int = #line, function: String = #function, error: Error? = nil) {
    }

    /// ErrorAndCrash-level messages are intended for reporting system-level or multi-process errors. Errors that should never happen
    /// or that may lead to unknown states of the app.
    /// ErrorAndCrash-level messages are always store in the device and shown in console. But also will crash the app when debug
    /// but not in Release
    ///
    ///
    /// - Parameters:
    ///   - file: literal String, representing the name of the file where the log was trigger. (autocompleted parameted)
    ///   - line: literal Int, representing the line number where the log was trigger. (autocompleted parameted)
    ///   - function: literal String, representing the name of the declaration where the log was trigger. (autocompleted parameted)
    ///   - message: optional String message that helps to understand or gives more details about the log. If nil message, empty
    ///   message information will be added on the log. Make sure to add the actual error at least.
    public func errorAndCrash(file: String = #file, line: Int = #line, function: String = #function, message: String? = nil) {
    }

    /// ErrorAndCrash-level messages are intended for reporting system-level or multi-process errors. Errors that should never happen
    /// or that may lead to unknown states of the app.
    /// ErrorAndCrash-level messages are always store in the device and shown in console. But also will crash the app when debug
    /// but not in Release
    ///
    ///
    /// - Parameters:
    ///   - file: literal String, representing the name of the file where the log was trigger. (autocompleted parameted)
    ///   - line: literal Int, representing the line number where the log was trigger. (autocompleted parameted)
    ///   - function: literal String, representing the name of the declaration where the log was trigger. (autocompleted parameted)
    ///   - error: optional Error that helps to understand what went wrong. This is the actual error that we get from the app (if any).
    ///   If nil error is pass, empty error information will be added on the log.
    public func errorAndCrash(file: String = #file, line: Int = #line, function: String = #function, error: Error? = nil) {
    }
}

//private enum LogType {
//    case log, debug, info, warn, error, errorAndCrash
//}
