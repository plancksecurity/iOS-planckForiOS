//
//  LogService.swift
//  pEp
//
//  Created by Dirk Zimmermann on 13.12.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation
import os.log

protocol LogServicing: class {
    func debug(_ message: StaticString, _ args: CVarArg...)
    func info(_ message: StaticString, _ args: CVarArg...)
    func error(_ message: StaticString, _ args: CVarArg...)
}

enum LogType {
    case debug
    case info
    case error
    case fault
    case normal
}

public class LogService: LogServicing {
    public init(subsystem: String = Bundle.main.bundleIdentifier ?? "", category: String = "") {
        if #available(iOS 10.0, macOS 10.12, tvOS 10.0, watchOS 3.0, *) {
            let osLog = OSLog(subsystem: subsystem, category: category)
            self.osLog = osLog
        }
        self.subsystem = subsystem
        self.category = category
    }

    public func debug(_ message: StaticString, _ args: CVarArg...) {
        internalLog(type: .debug, message: message, args)
    }

    public func info(_ message: StaticString, _ args: CVarArg...) {
        internalLog(type: .info, message: message, args)
    }

    public func error(_ message: StaticString, _ args: CVarArg...) {
        internalLog(type: .error, message: message, args)
    }

    public func log(_ message: StaticString, _ args: CVarArg...) {
        internalLog(type: .normal, message: message, args)
    }

    private var osLog: OSLog?
    private let subsystem: String
    private let category: String

    private func log(type: LogType, message: StaticString) {
        internalLog(type: type, message: message, "")
    }

    private func internalLog(type: LogType, message: StaticString, _ args: CVarArg...) {
        if #available(iOS 10.0, macOS 10.12, tvOS 10.0, watchOS 3.0, *) {
            guard let osLog = osLog else { return }
            let logType: OSLogType
            switch type {
            case .debug:
                logType = .debug
            case .error:
                logType = .error
            case .fault:
                logType = .fault
            case .info:
                logType = .info
            case .normal:
                logType = .default
            }
            os_log(message, log: osLog, type: logType, args)
        } else {
            NSLog(message.description, args)
        }
    }
}
