//
//  LoggingViewModel.swift
//  pEp
//
//  Created by Dirk Zimmermann on 07.10.20.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation

import pEpIOSToolbox

public protocol LogViewModelDelegate: class {
    /// The view should be updated with the latest log contents.
    /// - Note: The updates _may_ occur every `updateInterval`, regardless
    /// if the log changed or not.
    func updateLogContents(logString: String)
}

public class LoggingViewModel {
    /// Update interval in seconds.
    ///
    /// The VM will pull the latest log string every interval and inform
    /// the delegate via `updateLogContents`.
    public var updateInterval: TimeInterval = 2.0

    /// The delegate for log updates
    public weak var delegate: LogViewModelDelegate?

    public init() {
        setupTimers()
    }

    private var timer: Timer?

    private func setupTimers() {
        let theTimer = Timer(fire: Date(timeIntervalSinceNow: updateInterval),
                             interval: updateInterval,
                             repeats: true) { [weak self] timer in
            guard let me = self else {
                // can happen, e.g. owning VC goes out of view/scope
                return
            }
            let logString = Log.shared.getLatestLogString()
            me.delegate?.updateLogContents(logString: logString)
        }
        timer = theTimer
    }

    deinit {
        timer?.invalidate()
    }
}
