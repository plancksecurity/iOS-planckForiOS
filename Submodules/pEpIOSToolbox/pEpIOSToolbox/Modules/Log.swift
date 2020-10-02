//
//  Log.swift
//  pEpIOSToolbox
//
//  Created by Alejandro Gelos on 03/05/2019.
//  Copyright © 2019 pEp Security SA. All rights reserved.
//

import Foundation

class LoggerSettingsProvider: LoggerSettingsProviderProtocol {
    func loglevelChanged(to newLogLevel: LoggerSettingsProviderLogLevel) {
    }
}

/// Shared instance of logger.
class Log {
    static let shared = Logger(subsystem: "security.pEp.pEpIOSToolbox", category: "general")

    /// Init is forbidden. Singleton...
    private init() {}
}
