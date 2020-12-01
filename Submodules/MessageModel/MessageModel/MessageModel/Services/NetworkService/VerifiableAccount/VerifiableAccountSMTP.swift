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
        let error = SmtpSendError.badResponse(name)
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
    }

    func authenticationFailed(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {
        notify(error: SmtpSendError.authenticationFailed(
            #function,
            smtpConnection.accountAddress))
    }

    func connectionEstablished(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {}

    func connectionLost(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {
        if let error = theNotification?.userInfo?[PantomimeErrorExtra] as? NSError {
            notify(error: SmtpSendError.connectionLost(#function, error.localizedDescription))
        } else {
            notify(error: SmtpSendError.connectionLost(#function, nil))
        }
    }

    func connectionTerminated(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {
        notify(error: SmtpSendError.connectionTerminated(#function))
    }

    func connectionTimedOut(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {
        if let error = theNotification?.userInfo?[PantomimeErrorExtra] as? NSError {
            notify(error: SmtpSendError.connectionTimedOut(#function, error.localizedDescription))
        } else {
            notify(error: SmtpSendError.connectionTimedOut(#function, nil))
        }
    }

    func badResponse(_ smtpConnection: SmtpConnectionProtocol, response: String?) {
        notify(error: SmtpSendError.badResponse(#function))
    }

    func requestCancelled(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {
        notifyUnexpectedCallback(name: #function)
    }

    func serviceInitialized(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {
        delegate?.verified(verifier: self, result: .success(()))
    }

    func serviceReconnected(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {
        notifyUnexpectedCallback(name: #function)
    }
}
