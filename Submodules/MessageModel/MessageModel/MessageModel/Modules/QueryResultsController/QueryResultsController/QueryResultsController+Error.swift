//
//  QueryResultsController+Error.swift
//  MessageModel
//
//  Created by Andreas Buff on 22.02.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

extension QueryResultsController {
    enum InvalidStateError: Error {
        case notInitialized
        case notMonitoring
        case alreadyMonitoring
        case isCurrentlyUpdatingModel
        case unknownInternalInvalidState
    }
}
