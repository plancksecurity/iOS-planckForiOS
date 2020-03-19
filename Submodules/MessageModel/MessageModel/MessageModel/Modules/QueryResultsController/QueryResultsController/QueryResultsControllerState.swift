//
//  QueryResultsControllerState.swift
//  MessageModel
//
//  Created by Andreas Buff on 20.02.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation

enum QueryResultsControllerState {
    /// Initial state
    case uninitialized

    /// The object has been initialized successfully.
    case initialized

    /// The QueryResultsController is monitoring the results of the given query and will inform
    /// the delegate in case of any changes.
    /// It is save to access `results` in this (and only in this) state.
    case monitoringResults

    /// Relevant database changes have been dectected and the results are currently updated.
    /// You MUST NOT access `results` in this state.
    case updatingResults
}
