//
//  VerifiableAccountSMTP.swift
//  pEp
//
//  Created by Dirk Zimmermann on 17.04.19.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import Foundation

import PantomimeFramework

#if EXT_SHARE
import pEpIOSToolboxForExtensions
#else
import pEpIOSToolbox
#endif

protocol VerifiableAccountSMTPDelegate: AnyObject {
    func verified(verifier: VerifiableAccountSMTP,
                  result: Result<Void, Error>)
}

/// Helper for `VerifiableAccount` (verifies SMTP servers).
class VerifiableAccountSMTP {
    weak var delegate: VerifiableAccountSMTPDelegate?
    private var smtpConnection: SmtpConnection?

    /// Tries to verify the given IMAP account.
    func verify(connectInfo: EmailConnectInfo) {
        smtpConnection = SmtpConnection(connectInfo: connectInfo)
        smtpConnection?.delegate = self
        smtpConnection?.start()
    }
}

// Mark: - SmtpConnectionDelegate

extension VerifiableAccountSMTP: SmtpConnectionDelegate {
    private func notifyUnexpectedCallback(name: String) {
        let error = SmtpSendError.badResponse(name, nil)
        delegate?.verified(verifier: self, result: .failure(error))
    }

    private func notify(error: Error) {
        delegate?.verified(verifier: self, result: .failure(error))
    }

    func messageSent(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {
        notifyUnexpectedCallback(name: #function)
    }

    func messageNotSent(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {
        notifyUnexpectedCallback(name: #function)
    }

    func transactionInitiationCompleted(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {
        notifyUnexpectedCallback(name: #function)
    }

    func transactionInitiationFailed(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {
        notifyUnexpectedCallback(name: #function)
    }

    func recipientIdentificationCompleted(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {
        notifyUnexpectedCallback(name: #function)
    }

    func recipientIdentificationFailed(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {
        notifyUnexpectedCallback(name: #function)
    }

    func transactionResetCompleted(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {
        notifyUnexpectedCallback(name: #function)
    }

    func transactionResetFailed(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {
        notifyUnexpectedCallback(name: #function)
    }

    func authenticationCompleted(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {
        delegate?.verified(verifier: self, result: .success(()))
    }

    func authenticationFailed(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {
        let serverErrorInfo = ServerErrorInfo(
                        port: smtpConnection.port,
                        server: smtpConnection.server,
                        connectionTransport: smtpConnection.connectionTransport)

        notify(error: SmtpSendError.authenticationFailed(
            #function,
            smtpConnection.accountAddress, serverErrorInfo))
    }

    func connectionEstablished(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {}

    func connectionLost(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {
        if let error = theNotification?.userInfo?[PantomimeErrorExtra] as? NSError {
            let serverErrorInfo = ServerErrorInfo(
                            port: smtpConnection.port,
                            server: smtpConnection.server,
                            connectionTransport: smtpConnection.connectionTransport)

            notify(error: SmtpSendError.connectionLost(#function, error.localizedDescription, serverErrorInfo))
        } else {
            let serverErrorInfo = ServerErrorInfo(
                            port: smtpConnection.port,
                            server: smtpConnection.server,
                            connectionTransport: smtpConnection.connectionTransport)

            notify(error: SmtpSendError.connectionLost(#function, nil, serverErrorInfo))
        }
    }

    func connectionTerminated(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {
        let serverErrorInfo = ServerErrorInfo(
                        port: smtpConnection.port,
                        server: smtpConnection.server,
                        connectionTransport: smtpConnection.connectionTransport)

        notify(error: SmtpSendError.connectionTerminated(#function, serverErrorInfo))
    }

    func connectionTimedOut(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {
        let serverErrorInfo = ServerErrorInfo(
                        port: smtpConnection.port,
                        server: smtpConnection.server,
                        connectionTransport: smtpConnection.connectionTransport)

        if let error = theNotification?.userInfo?[PantomimeErrorExtra] as? NSError {
            notify(error: SmtpSendError.connectionTimedOut(#function, error.localizedDescription, serverErrorInfo))
        } else {
            notify(error: SmtpSendError.connectionTimedOut(#function, nil, serverErrorInfo))
        }
    }

    func badResponse(_ smtpConnection: SmtpConnectionProtocol, response: String?) {
        let serverErrorInfo = ServerErrorInfo(
                        port: smtpConnection.port,
                        server: smtpConnection.server,
                        connectionTransport: smtpConnection.connectionTransport)

        notify(error: SmtpSendError.badResponse(#function, serverErrorInfo))
    }

    func requestCancelled(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {
        notifyUnexpectedCallback(name: #function)
    }

    func serviceInitialized(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) { }

    func serviceReconnected(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {
        notifyUnexpectedCallback(name: #function)
    }
}
