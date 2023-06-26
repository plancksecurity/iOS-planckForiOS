//
//  EncryptAndSMTPSendService.swift
//  MessageModel
//
//  Created by Andreas Buff on 26.09.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import CoreData

import PlanckToolbox

/// Service that handles sending of messages for one SMTP supporting account.
/// Usage:
/// * init
/// * `start()`
/// * optionally `stop()` or `finish()`
class EncryptAndSMTPSendService: QueryBasedService<CdMessage>, SendServiceProtocol {
    weak private var encryptionErrorDelegate: EncryptionErrorDelegate?
    weak private var auditLogger: AuditLoggingProtocol?

    /// Creates a ready to go SMTP Encrypt and Send Service
    ///
    /// - Parameters:
    ///   - backgroundTaskManager:  see Service.init for docs
    ///   - cdAccount:  Account to encrypt and send messages for.
    ///                - note: MUST life on QueryBasedService's context!
    ///   see Service.init for docs
    init(backgroundTaskManager: BackgroundTaskManagerProtocol? = nil,
         cdAccount: CdAccount,
         encryptionErrorDelegate: EncryptionErrorDelegate? = nil,
         errorPropagator: ErrorContainerProtocol?,
         auditLogger: AuditLoggingProtocol? = nil) {
        let predicate = CdMessage.PredicateFactory.outgoingMails(in: cdAccount)
        self.encryptionErrorDelegate = encryptionErrorDelegate
        self.auditLogger = auditLogger

        super.init(useSerialQueue: true,
                   backgroundTaskManager: backgroundTaskManager,
                   predicate: predicate,
                   cacheName: nil,
                   sortDescriptors: [NSSortDescriptor(key: "sent", ascending: true)],
                   errorPropagator: errorPropagator)
    }

    // MARK: - Overrides

    override func operations() -> [Operation] {
        var createes = [Operation]()
        privateMoc.performAndWait { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            let cdMessagesToSend = me.results

            guard !cdMessagesToSend.isEmpty else {
                // Nothing to do
                return
            }

            guard
                let cdAccount = cdMessagesToSend.first?.parent?.account,
                let smtpConnectInfo = cdAccount.smtpConnectInfo else {
                Log.shared.error("%@ - No account", "\(type(of: self))")
                let reportErrorAndWaitOp = me.errorHandlerOp(error: BackgroundError.SmtpError.invalidAccount)
                createes.append(reportErrorAndWaitOp)
                return
            }
            let smtpConnection = SmtpConnection(connectInfo: smtpConnectInfo)

            // Login
            let loginOP = LoginSmtpOperation(smtpConnection: smtpConnection,
                                             errorContainer: me.errorPropagator)
            createes.append(loginOP)

            // Send
            for cdMsg in cdMessagesToSend {
                let sendOp = EncryptAndSMTPSendMessageOperation(cdMessageToSendObjectId: cdMsg.objectID,
                                                                smtpConnection: smtpConnection,
                                                                errorContainer: me.errorPropagator,
                                                                encryptionErrorDelegate: me.encryptionErrorDelegate,
                                                                auditLogger: me.auditLogger)
                createes.append(sendOp)
            }
            // Add error handler
            createes.append(me.errorHandlerOp())
        }
        return createes
    }
}
