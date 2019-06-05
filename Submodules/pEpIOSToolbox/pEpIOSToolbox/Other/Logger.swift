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
    public init(subsystem: String = "security.pEp.app.iOS", category: String) {
        self.subsystem = subsystem
        self.category = category
        osLogger = OSLog(subsystem: subsystem, category: category)
    }

    public func errorAndCrash(function: String = #function,
                              filePath: String = #file,
                              fileLine: Int = #line,
                              _ message: StaticString? = nil) {
        SystemUtils.crash("\(filePath):\(function):\(fileLine) - \(message ?? "no message")")
    }

    public func errorAndCrash(function: String = #function,
                              filePath: String = #file,
                              fileLine: Int = #line,
                              error: Error) {
        SystemUtils.crash("\(filePath):\(function):\(fileLine) - \(error)")
    }

    public func log(function: String = #function,
                    filePath: String = #file,
                    fileLine: Int = #line,
                    error: Error) {
        // Error is not supported by "%@", because it doesn't conform to CVArg
        // and CVArg is only meant for internal types.
        // An alternative would be to use localizedDescription(),
        // but if they are indeed localized you end up with international
        // log messages.
        // So we wrap it into an NSError which does suppord CVArg.
        let nsErr = NSError(domain: subsystem, code: 0, userInfo: [NSUnderlyingErrorKey: error])
        os_log("Error (%{public}@ %{public}@:%d) %{public}@",
               log: Log.shared.osLogger,
               type: .error,
               function,
               filePath,
               fileLine,
               nsErr)
    }

    /**
     Since this kind of logging is used so often in the codebase, it has its
     own method.
     */
    public func lostMySelf() {
        errorAndCrash("Lost MySelf")
    }

    private let subsystem: String
    private let category: String

    public let osLogger: OSLog
}
