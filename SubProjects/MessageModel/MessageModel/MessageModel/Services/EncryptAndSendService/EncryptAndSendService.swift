//
//  EncryptAndSendService.swift
//  MessageModel
//
//  Created by Andreas Buff on 26.09.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import CoreData

protocol SendServiceProvider {

    /// Returns the Service responsible for sending messages marked for sending.
    func sendService(backgroundTaskManager: BackgroundTaskManagerProtocol?,
                     errorPropagator: ErrorPropagator,
                     runOnce: Bool) -> SendServiceProtocol?
}

/// Service that sends all messages to be send after starting it. It creates and manages one
/// service per account.
/// Usage:
/// * init
/// * `start()`
/// * optionally `stop()` or `finish()`
class EncryptAndSendService: PerAccountService {

    // MARK: - PerAccountServiceAbstractProtocol

    override func service(for cdAccount: CdAccount,
                          backgroundTaskManager: BackgroundTaskManagerProtocol,
                          errorPropagator: ErrorPropagator) -> ServiceProtocol? {
        return cdAccount.sendService(backgroundTaskManager: backgroundTaskManager,
                                     errorPropagator: errorPropagator)
    }
}
