//
//  LoggingViewModel.swift
//  pEp
//
//  Created by Dirk Zimmermann on 07.10.20.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation

import pEpIOSToolbox

public protocol LiveLogViewModelDelegate: class {
    /// The view should be updated with the latest log contents.
    /// - Note: The updates _may_ occur every `updateInterval`, regardless
    /// if the log changed or not.
    func updateLogContents(logString: String)
}

public class LiveLogViewModel {
    /// Update interval in seconds.
    ///
    /// The VM will pull the latest log string every interval and inform
    /// the delegate via `updateLogContents`.
    public var updateInterval: TimeInterval = 2.0

    /// The delegate for log updates
    public weak var delegate: LiveLogViewModelDelegate? {
        didSet {
            sendTheLog()
        }
    }

    public init() {
        setupTimers()
        sendTheLog()
    }

    deinit {
        timer?.invalidate()
    }

    // MARK: - Private

    private var timer: Timer?

    private func sendTheLog() {
        if let theDelegate = delegate {
            let logString = Log.shared.getLatestLogString()
            theDelegate.updateLogContents(logString: logString)
        }
    }

    private func setupTimers() {
        let theTimer = Timer.scheduledTimer(withTimeInterval: updateInterval,
                                            repeats: true) { [weak self] timer in
            guard let me = self else {
                // can happen, e.g. owning VC goes out of view/scope
                return
            }
            me.sendTheLog()
        }
        timer = theTimer
    }
}
