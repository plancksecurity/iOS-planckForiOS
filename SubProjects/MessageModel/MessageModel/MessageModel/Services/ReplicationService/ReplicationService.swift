//
//  ReplicationService.swift
//  MessageModel
//
//  Created by Andreas Buff on 15.10.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation

import pEpIOSToolbox

/// If you conform to this you must guarantee the provided Servcie is appropriate for syncing the
/// server state with the local persistence store. If there is no appropriate service it is OK to
/// return `nil though.
protocol ReplicationServiceProvider {

    /// Returns the Service responsible for syncing server and local store.
    func replicationService(backgroundTaskManager: BackgroundTaskManagerProtocol?,
                            errorPropagator: ErrorContainerProtocol) -> ReplicationServiceProtocol?
}

/// Every ReplicationService:
/// * must support ServcieProtocol methods (start, stop ...)
/// * must be able to handle fast polling
protocol ReplicationServiceProtocol: OperationBasedServiceProtocol, PollingDelegate {}

/// Service that replicates the server state for all accounts and keeps it updated once `start()`
/// is called.
/// Usage:
/// * init
/// * `start()`
/// * optionally `stop()` or `finish()`
class ReplicationService: PerAccountService { 

    // MARK: - PerAccountServiceAbstractProtocol

    override func service(for cdAccount: CdAccount,
                          backgroundTaskManager: BackgroundTaskManagerProtocol? = nil,
                          errorPropagator: ErrorContainerProtocol) -> ServiceProtocol? {
        return cdAccount.replicationService(backgroundTaskManager: backgroundTaskManager,
                                            errorPropagator: errorPropagator)
    }
}

// MARK: - PollingDelegate

extension ReplicationService: ReplicationServiceProtocol {
    func enableFastPolling() {
        perAccountServices.forEach {
            guard let replicationService = $0 as? ReplicationServiceProtocol else {
                Log.shared.errorAndCrash("Wrong service type")
                return
            }
            replicationService.enableFastPolling()
        }
    }

    func disableFastPolling() {
        perAccountServices.forEach {
            guard let replicationService = $0 as? ReplicationServiceProtocol else {
                Log.shared.errorAndCrash("Wrong service type")
                return
            }
            replicationService.disableFastPolling()
        }
    }
}
