//
//  LoggerSettingsProviderProtocol.swift
//  pEpIOSToolbox
//
//  Created by Dirk Zimmermann on 02.10.20.
//  Copyright © 2020 pEp Security SA. All rights reserved.
//

import Foundation

/// High-level (app view) verbosity of the logging
enum LoggerSettingsProviderLogLevel {
    case normal
    case verbose
}

protocol LoggerSettingsProviderProtocol {
    /// Indicates a change in the level of logging verbosity
    func loglevelChanged(to newLogLevel: LoggerSettingsProviderLogLevel)
}
