//
//  AppSettings+LoggerSettingsProviderProtocol.swift
//  pEp
//
//  Created by Dirk Zimmermann on 02.10.20.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation

import pEpIOSToolbox

extension AppSettings: LoggerSettingsProviderProtocol {
    public func loglevelChanged(to newLogLevel: LoggerSettingsProviderLogLevel) {
        switch newLogLevel {
        case .normal:
            verboseLogginEnabled = false
        case .verbose:
            verboseLogginEnabled = true
        }
    }
}
