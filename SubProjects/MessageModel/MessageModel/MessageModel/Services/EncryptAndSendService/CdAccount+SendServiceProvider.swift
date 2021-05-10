//
//  CdAccount+SendServiceProvider.swift
//  MessageModel
//
//  Created by Andreas Buff on 17.10.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import CoreData

import pEpIOSToolbox

// MARK: - CdAccount+SendServiceProvider

extension CdAccount: SendServiceProvider {

    func sendService(backgroundTaskManager: BackgroundTaskManagerProtocol? = nil,
                     encryptionErrorDelegate: EncryptionErrorDelegate? = nil,
                     errorPropagator: ErrorContainerProtocol) -> SendServiceProtocol? {
        // Currently we do support SMTP only. When you are about to implement other protocols
        // (e.g. Acitve Sync), this var MUST return the appropriate service for the protocol.
        if let _ = server(type: .smtp) {
            return EncryptAndSMTPSendService(backgroundTaskManager: backgroundTaskManager,
                                             cdAccount: self,
                                             encryptionErrorDelegate: encryptionErrorDelegate,
                                             errorPropagator: errorPropagator)
        } else {
            Log.shared.errorAndCrash("Send protocol yet unsupported. If the account does not use SMTP for sending, add impl here.")
        }
        return nil
    }
}
