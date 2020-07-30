//
//  Throttler.swift
//  pEp
//
//  Created by Martin Brude on 30/07/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation

/// Class that aims to regulate the frequency at a certain process runs as well as the queue where it's trigger.
class Throttler {

    private var workItem: DispatchWorkItem = DispatchWorkItem(block: {})
    private var previousRun: Date = Date.distantPast
    private let queue: DispatchQueue
    private let minimumDelay: TimeInterval

    init(minimumDelay: TimeInterval = 0.0, queue: DispatchQueue = DispatchQueue.main) {
        self.minimumDelay = minimumDelay
        self.queue = queue
    }

    /// Execute the block passed by parameter taking into the account the required minimum delay.
    /// - Parameter block: The block to execute.
    public func throttle(_ block: @escaping () -> Void) {
        // Cancel any existing work item if it has not yet executed
        workItem.cancel()

        // Re-assign workItem with the new block task, resetting the previousRun time when it executes
        workItem = DispatchWorkItem() { [weak self] in
            guard let me = self else {
                // Valid case: the object that references this class could be deallocated.
                // If so, just do not execute the action.
                return
            }
            me.previousRun = Date()
            block()
        }

        // If the time since the previous run is more than the required minimum delay,
        // execute the workItem immediately, else delay the workItem execution by the minimum delay time
        let delay = previousRun.timeIntervalSinceNow > minimumDelay ? 0 : minimumDelay
        queue.asyncAfter(deadline: .now() + Double(delay), execute: workItem)
    }
}
