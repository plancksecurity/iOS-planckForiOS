//
//  PEPLogger.swift
//  PEPLogger
//
//  Created by Alejandro Gelos on 17/01/2020.
//  Copyright © 2020 Alejandro Gelos. All rights reserved.
//

import Foundation

@objcMembers

/// This is a logging API  for capturing messaging across all levels of the system.
/// There are several log levels employed by this logger, which correspond to the different types of messages your app may need to
/// capture, and define when messages are store in the device (in a text file), shown in console or both.
/// Debug logging is a custom Swift flag that this logger uses, to identify when is debug o release target. And behave accordingly.
/// To enable debug logging, add a Swift Flag to the target named -DPEPDEBUG_LOGGING (in target, build settings, Swift flags).
///
/// If the text file store in the device reach the maximum size, another text file will be created to continue logging.
/// A literal is the source code representation of a value of a type (in this case String and Ints). And will be autocompleted with the correct
/// information, from where the log was trigger. Do not pass any parameter there, unless you need it.
/// It's recommended to add a description message of the error, sometimes errors may not contain much information.
///
/// Note: This API was created to have all the log in one text file. So the end user  can easily share captured logs from the text file, to
/// the developer team for debug purpose. Example with a button in Settings.
public class Logger: NSObject {

    /// Debug-level messages are intended to be use in a development environment and not in shipping software.
    /// Debug-level messages are only shown in console when debug logging Swift flags, is set in target.
    /// Note that nothing will be store in the device.
    ///
    /// - Parameters:
    ///   - file: literal String, representing the name of the file where the log was trigger. (autocompleted parameted)
    ///   - line: literal Int, representing the line number where the log was trigger. (autocompleted parameted)
    ///   - function: literal String, representing the name of the declaration where the log was trigger. (autocompleted parameted)
    ///   - message: optional String message that helps to understand or gives more details about the log. If nil message, no
    ///   message information will be added on the log. Make sure to add the actual error at least.
    ///   - error: optional Error that helps to understand what went wrong. This is the actual error that we get from the app (if any).
    ///   If nil error is pass, no error information will be added on the log. Then make sure to add a good description message instead.
    public func debug(file: String = #file, line: Int = #line, function: String = #function, message: String? = nil, error: Error? = nil) {

    }

    /// Info-level messages are intended for capturing information that may be helpful, but isn’t essential, for troubleshooting errors.
    /// Info-level messages are store in the device and also shown in console when debug logging Swift flags is set in target.
    ///
    /// - Parameters:
    ///   - file: literal String, representing the name of the file where the log was trigger. (autocompleted parameted)
    ///   - line: literal Int, representing the line number where the log was trigger. (autocompleted parameted)
    ///   - function: literal String, representing the name of the declaration where the log was trigger. (autocompleted parameted)
    ///   - message: optional String message that helps to understand or gives more details about the log. If nil message, no
    ///   message information will be added on the log. Make sure to add the actual error at least.
    ///   - error: optional Error that helps to understand what went wrong. This is the actual error that we get from the app (if any).
    ///   If nil error is pass, no error information will be added on the log. Then make sure to add a good description message instead.
    public func info(file: String = #file, line: Int = #line, function: String = #function, message: String? = nil, error: Error? = nil) {

    }

    /// Warn-level messages are intended for capturing information about things that might result a failure.
    /// Warn-level messages are shown in console and  also store in the device.
    ///
    /// - Parameters:
    ///   - file: literal String, representing the name of the file where the log was trigger. (autocompleted parameted)
    ///   - line: literal Int, representing the line number where the log was trigger. (autocompleted parameted)
    ///   - function: literal String, representing the name of the declaration where the log was trigger. (autocompleted parameted)
    ///   - message: optional String message that helps to understand or gives more details about the log. If nil message, no
    ///   message information will be added on the log. Make sure to add the actual error at least.
    ///   - error: optional Error that helps to understand what went wrong. This is the actual error that we get from the app (if any).
    ///   If nil error is pass, no error information will be added on the log. Then make sure to add a good description message instead.
    public func warn(file: String = #file, line: Int = #line, function: String = #function, message: String? = nil, error: Error? = nil) {

    }

    /// Error-level messages are intended for reporting process-level errors. But not critical errors that lead to unknown states of the app.
    /// Error-level messages are always store in the device and shown in console. And will NOT crash the app, just log the error.
    ///
    /// - Parameters:
    ///   - file: literal String, representing the name of the file where the log was trigger. (autocompleted parameted)
    ///   - line: literal Int, representing the line number where the log was trigger. (autocompleted parameted)
    ///   - function: literal String, representing the name of the declaration where the log was trigger. (autocompleted parameted)
    ///   - message: optional String message that helps to understand or gives more details about the log. If nil message, no
    ///   message information will be added on the log. Make sure to add the actual error at least.
    ///   - error: optional Error that helps to understand what went wrong. This is the actual error that we get from the app (if any).
    ///   If nil error is pass, no error information will be added on the log. Then make sure to add a good description message instead.
    public func error(file: String = #file, line: Int = #line, function: String = #function, message: String? = nil, error: Error? = nil) {

    }

    /// ErrorAndCrash-level messages are intended for reporting system-level or multi-process errors. Errors that should never happen
    /// or that may lead to unknown states of the app.
    /// ErrorAndCrash-level messages are always store in the device and shown in console. But also will crash the app when debug
    /// logging Swift flags is set in target.
    ///
    ///
    /// - Parameters:
    ///   - file: literal String, representing the name of the file where the log was trigger. (autocompleted parameted)
    ///   - line: literal Int, representing the line number where the log was trigger. (autocompleted parameted)
    ///   - function: literal String, representing the name of the declaration where the log was trigger. (autocompleted parameted)
    ///   - message: optional String message that helps to understand or gives more details about the log. If nil message, no
    ///   message information will be added on the log. Make sure to add the actual error at least.
    ///   - error: optional Error that helps to understand what went wrong. This is the actual error that we get from the app (if any).
    ///   If nil error is pass, no error information will be added on the log. Then make sure to add a good description message instead.
    public func errorAndCrash(file: String = #file, line: Int = #line, function: String = #function, message: String? = nil, error: Error? = nil) {

    }
}

//private enum LogType {
//    case log, debug, info, warn, error, errorAndCrash
//}
