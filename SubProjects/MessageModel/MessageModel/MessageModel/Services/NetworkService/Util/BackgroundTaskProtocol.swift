//
//  BackgroundTaskProtocol.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 15/12/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

public typealias BackgroundTaskID = UIBackgroundTaskIdentifier

/**
 Abstract away the iOS way of doing things in the background, so this can be mocked
 independently of UIApplication.
 */
public protocol BackgroundTaskProtocol {
    func beginBackgroundTask(taskName: String?) -> BackgroundTaskID
    func beginBackgroundTask() -> BackgroundTaskID
    func beginBackgroundTask(expirationHandler: (() -> Void)?) -> BackgroundTaskID
    func beginBackgroundTask(taskName: String?,
                             expirationHandler: (() -> Void)?) -> BackgroundTaskID
    func endBackgroundTask(_ taskID: BackgroundTaskID?)
}

public extension BackgroundTaskProtocol {
    func beginBackgroundTask(taskName: String?) -> BackgroundTaskID {
        return beginBackgroundTask(taskName: taskName, expirationHandler: nil)
    }

    func beginBackgroundTask() -> BackgroundTaskID {
        return beginBackgroundTask(taskName: nil, expirationHandler: nil)
    }

    func beginBackgroundTask(expirationHandler: (() -> Void)? = nil) -> BackgroundTaskID {
        return beginBackgroundTask(taskName: nil, expirationHandler: expirationHandler)
    }
}
