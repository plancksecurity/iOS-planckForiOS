//
//  Log.swift
//  pEp
//
//  Created by Alejandro Gelos on 12/04/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import pEpIOSToolbox

/// Shared instance of logger.
class Log {
    static let shared = Logger(subsystem: "security.pEp.app.pEpForiOS",
                               category: "general",
                               loggerSettingsProvider: AppSettings.shared)

    /// Init is forbidden. Singleton...
    private init() {}
}

