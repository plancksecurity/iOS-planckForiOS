//
//  PollingDelegate.swift
//  MessageModel
//
//  Created by Andreas Buff on 02.07.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation

/// Is responsible to listen to polling mode changes.
/// Fast polling is enabled by e.g. KeySync to send & receive messages as fast as possible.
protocol PollingDelegate: class {

    /// Called whenever fast polling is required.
    func enableFastPolling()

    /// Called whenever fast polling is not required any more.
    func disableFastPolling()
}
