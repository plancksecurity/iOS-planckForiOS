//
//  Log.swift
//  pEpIOSToolbox
//
//  Created by Alejandro Gelos on 03/05/2019.
//  Copyright © 2019 pEp Security SA. All rights reserved.
//

import Foundation

class LoggerSettingsProvider: LoggerSettingsProviderProtocol {
    func isVerboseLogging() -> Bool {
        return true
    }
}

/// Shared instance of logger.
class Log {
    static let shared = Logger(subsystem: "security.pEp.pEpIOSToolbox",
                               category: "general",
                               loggerSettingsProvider: LoggerSettingsProvider())

    /// Init is forbidden. Singleton...
    private init() {}
}
