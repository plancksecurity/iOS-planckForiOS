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
                     encryptionErrorDelegate: EncryptionErrorDelegate?,
                     errorPropagator: ErrorContainerProtocol,
                     auditLogger: AuditLoggingProtocol?) -> SendServiceProtocol?
}

/// Service that sends all messages to be send after starting it. It creates and manages one
/// service per account.
/// Usage:
/// * init
/// * `start()`
/// * optionally `stop()` or `finish()`
class EncryptAndSendService: PerAccountService {
    weak private var encryptionErrorDelegate: EncryptionErrorDelegate?
    weak private var auditLogger: AuditLoggingProtocol?

    required init(backgroundTaskManager: BackgroundTaskManagerProtocol? = nil,
                  encryptionErrorDelegate: EncryptionErrorDelegate? = nil,
                  errorPropagator: ErrorPropagator?,
                  auditLogger: AuditLoggingProtocol? = nil) {
        self.auditLogger = auditLogger
        self.encryptionErrorDelegate = encryptionErrorDelegate
        super.init(backgroundTaskManager: backgroundTaskManager, errorPropagator: errorPropagator)
    }

    // MARK: - PerAccountServiceAbstractProtocol

    override func service(for cdAccount: CdAccount,
                          backgroundTaskManager: BackgroundTaskManagerProtocol,
                          errorPropagator: ErrorContainerProtocol) -> ServiceProtocol? {
        return service(for: cdAccount,
                       backgroundTaskManager: backgroundTaskManager,
                       encryptionErrorDelegate: encryptionErrorDelegate,
                       errorPropagator: errorPropagator,
                       auditLogger: self.auditLogger)
    }

    func service(for cdAccount: CdAccount,
                 backgroundTaskManager: BackgroundTaskManagerProtocol,
                 encryptionErrorDelegate: EncryptionErrorDelegate? = nil,
                 errorPropagator: ErrorContainerProtocol,
                 auditLogger: AuditLoggingProtocol? = nil) -> ServiceProtocol? {
        return cdAccount.sendService(backgroundTaskManager: backgroundTaskManager,
                                     encryptionErrorDelegate: encryptionErrorDelegate,
                                     errorPropagator: errorPropagator,
                                     auditLogger: auditLogger)
    }
}
