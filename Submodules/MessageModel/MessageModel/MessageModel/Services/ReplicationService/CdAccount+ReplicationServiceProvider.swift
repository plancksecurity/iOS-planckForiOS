//
//  CdAccount+ReplicationServiceProvider.swift
//  MessageModel
//
//  Created by Andreas Buff on 17.10.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import CoreData

import pEpIOSToolbox

// MARK: - CdAccount+ReplicationServiceProvider

extension CdAccount: ReplicationServiceProvider {

    func replicationService(backgroundTaskManager: BackgroundTaskManagerProtocol? = nil,
                            errorPropagator: ErrorPropagator) -> ReplicationServiceProtocol? {
        // Currently we do support IMAP only. When you are about to implement other protocols
        // (e.g. Acitve Sync), this var MUST return the appropriate service for the protocol.
        if let _ = server(type: .imap) {
            return ImapReplicationService(backgroundTaskManager: backgroundTaskManager,
                                          cdAccountObjectID: objectID,
                                          errorPropagator: errorPropagator)
        } else {
            Log.shared.errorAndCrash("Send protocol yet unsupported. If the account does not use the IMAP protocol, add impl here.")
        }
        return nil
    }
}
