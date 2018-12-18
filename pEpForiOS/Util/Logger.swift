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

    private let subsystem: String?
    private let category: String?

    private let osLogger: Any?

    private func saveLog(severity: Severity,
                         function: String = #function,
                         filePath: String = #file,
                         fileLine: Int = #line,
                         message: StaticString,
                         args: CVarArg) {
        // TODO: Invoke os_log()
    }
}
