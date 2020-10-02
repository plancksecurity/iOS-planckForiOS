//
//  Log.swift
//  MessageModel
//
//  Created by Andreas Buff on 01.03.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import pEpIOSToolbox

/// Shared instance of logger.
class Log {
    static let shared = Logger()

    /// Init is forbidden. Singleton...
    private init() {}
}
