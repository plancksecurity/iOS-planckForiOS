//
//  Log.swift
//  pEpIOSToolbox
//
//  Created by Alejandro Gelos on 03/05/2019.
//  Copyright © 2019 pEp Security SA. All rights reserved.
//

import Foundation

/// Shared instance of logger.
@objc public class Log: NSObject {
    @objc static public let shared = Logger()

    /// Init is forbidden. Singleton...
    private override init() {}
}