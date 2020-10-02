//
//  Log.swift
//  MessageModel
//
//  Created by Andreas Buff on 01.03.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import pEpIOSToolbox

class LoggerSettingsProvider: LoggerSettingsProviderProtocol {
    func isVerboseLogging() -> Bool {
        return true
    }
}

/// Shared instance of logger.
class Log {
    static let shared = Logger(subsystem: "security.pEp.app.pEpForiOS.MessageModel",
                               category: "general",
                               loggerSettingsProvider: LoggerSettingsProvider())

    /// Init is forbidden. Singleton...
    private init() {}
}
