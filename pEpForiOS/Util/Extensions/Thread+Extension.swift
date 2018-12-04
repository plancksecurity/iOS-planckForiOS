//
//  Thread+Extension.swift
//  pEp
//
//  Created by Dirk Zimmermann on 04.12.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

extension Thread {
    /**
     Use for debugging.
     */
    public var threadID: String {
        let defaultThreadName = "unknown"
        var threadName = Thread.current.name ?? defaultThreadName
        if threadName.isEmpty {
            threadName = defaultThreadName
        }
        if Thread.isMainThread {
            return "main (\(threadName))"
        } else {
            return "other (\(threadName))"
        }
    }

    public static var threadID: String {
        return Thread.current.threadID
    }
}
