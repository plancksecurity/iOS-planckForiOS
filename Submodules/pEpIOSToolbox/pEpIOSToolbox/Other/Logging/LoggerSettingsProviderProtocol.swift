//
//  LoggerSettingsProviderProtocol.swift
//  pEpIOSToolbox
//
//  Created by Dirk Zimmermann on 02.10.20.
//  Copyright © 2020 pEp Security SA. All rights reserved.
//

import Foundation

public protocol LoggerSettingsProviderProtocol {
    /// Indicates whether logging should be verbose or not
    func isVerboseLogging() -> Bool
}
