//
//  VerifiableAccountSMTP.swift
//  pEp
//
//  Created by Dirk Zimmermann on 17.04.19.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import Foundation

import PantomimeFramework
import pEpIOSToolbox

protocol VerifiableAccountSMTPDelegate: class {
    func verified(verifier: VerifiableAccountSMTP,
                  result: Result<Void, Error>)
}

/// Helper for `VerifiableAccount` (verifies SMTP servers).
class VerifiableAccountSMTP {
    public weak var delegate: VerifiableAccountSMTPDelegate?

    private var smtpConnection: SmtpConnection?

    /// Tries to verify the given IMAP account.
    public func verify(connectInfo: EmailConnectInfo) {
        smtpConnection = SmtpConnection(connectInfo: connectInfo)
        smtpConnection?.delegate = self
        smtpConnection?.start()
    }
}

// Mark: - SmtpConnectionDelegate

extension VerifiableAccountSMTP: SmtpConnectionDelegate {
    private func notifyUnexpectedCallback(name: String) {
        let error = SmtpSendError.badResponse(name)
        delegate?.verified(verifier: self, result: .failure(error))
    }

    private func notify(error: Error) {
        delegate?.verified(verifier: self, result: .failure(error))
    }

    public func messageSent(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {
        notifyUnexpectedCallback(name: #function)
    }

    public func messageNotSent(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {
        notifyUnexpectedCallback(name: #function)
    }

    public func transactionInitiationCompleted(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {
        notifyUnexpectedCallback(name: #function)
    }

    public func transactionInitiationFailed(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {
        notifyUnexpectedCallback(name: #function)
    }

    public func recipientIdentificationCompleted(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {
        notifyUnexpectedCallback(name: #function)
    }

    public func recipientIdentificationFailed(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {
        notifyUnexpectedCallback(name: #function)
    }

    public func transactionResetCompleted(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {
        notifyUnexpectedCallback(name: #function)
    }

    public func transactionResetFailed(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {
        notifyUnexpectedCallback(name: #function)
    }

    public func authenticationCompleted(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {
    }

    public func authenticationFailed(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {
        notify(error: SmtpSendError.authenticationFailed(
            #function,
            smtpConnection.accountAddress))
    }

    public func connectionEstablished(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {}

    public func connectionLost(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {
        if let error = theNotification?.userInfo?[PantomimeErrorExtra] as? NSError {
            notify(error: SmtpSendError.connectionLost(#function, error.localizedDescription))
        } else {
            notify(error: SmtpSendError.connectionLost(#function, nil))
        }
    }

    public func connectionTerminated(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {
        notify(error: SmtpSendError.connectionTerminated(#function))
    }

    public func connectionTimedOut(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {
        if let error = theNotification?.userInfo?[PantomimeErrorExtra] as? NSError {
            notify(error: SmtpSendError.connectionTimedOut(#function, error.localizedDescription))
        } else {
            notify(error: SmtpSendError.connectionTimedOut(#function, nil))
        }
    }

    public func badResponse(_ smtpConnection: SmtpConnectionProtocol, response: String?) {
        notify(error: SmtpSendError.badResponse(#function))
    }

    public func requestCancelled(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {
        notifyUnexpectedCallback(name: #function)
    }

    public func serviceInitialized(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {
        delegate?.verified(verifier: self, result: .success(()))
    }

    public func serviceReconnected(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {
        notifyUnexpectedCallback(name: #function)
    }
}
