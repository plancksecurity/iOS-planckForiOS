//
//  SystemUtils.swift
//  MessageModel
//
//  Created by Andreas Buff on 08/03/2017.
//  Copyright © 2017 pEp Security S.A. All rights reserved.
//

import Foundation

/// Crashes when in debug configuration
struct SystemUtils {
    static public func crash(_ message: String) {
        #if DEBUG
            preconditionFailure(message)
        #endif
    }
}
