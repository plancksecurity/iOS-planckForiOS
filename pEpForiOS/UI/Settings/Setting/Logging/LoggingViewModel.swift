//
//  LoggingViewModel.swift
//  pEp
//
//  Created by Dirk Zimmermann on 07.10.20.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation

protocol LogViewModelDelegate: class {
    /// The view should be updated with the latest log contents.
    /// - Note: The updates _may_ occur every `updateInterval`, regardless
    /// if the log changed or not.
    func updateLogContents(logString: String)
}

class LoggingViewModel {
    /// Update interval in seconds.
    ///
    /// The VM will pull the latest log string every interval and inform
    /// the delegate via `updateLogContents`.
    var updateInterval: TimeInterval = 2.0

    /// The delegate for log updates
    weak var delegate: LogViewModelDelegate?
}
