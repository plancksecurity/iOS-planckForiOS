//
//  VerifiableAccountSMTP.swift
//  pEp
//
//  Created by Dirk Zimmermann on 17.04.19.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import Foundation

import PantomimeFramework
import MessageModel
import pEpIOSToolbox

public protocol VerifiableAccountSMTPDelegate: class {
    func verified(verifier: VerifiableAccountSMTP,
                  basicConnectInfo: BasicConnectInfo,
                  result: Result<Void, Error>)
}

/// Helper for `VerifiableAccount` (verifies SMTP servers).
public class VerifiableAccountSMTP {
    public enum SmtpVerificationError: Error {
        /// The SMTP delegate got invoked with an unexpected method.
        case unexpected(String)
    }

    public weak var verifiableAccountDelegate: VerifiableAccountSMTPDelegate?

    private var smtpSend: SmtpSend?
    private var basicConnectInfo: BasicConnectInfo?

    /// Tries to verify the given IMAP account.
    public func verify(basicConnectInfo: BasicConnectInfo) {
        self.basicConnectInfo = basicConnectInfo

        smtpSend = SmtpSend(connectInfo: basicConnectInfo)
        smtpSend?.delegate = self
        smtpSend?.start()
    }
}

extension VerifiableAccountSMTP: SmtpSendDelegate {
    private func forcedConnectInfo() -> BasicConnectInfo {
        guard let theConnectInfo = basicConnectInfo else {
            return BasicConnectInfo(
                accountEmailAddress: "",
                loginName: nil,
                loginPassword: nil,
                accessToken: nil,
                networkAddress: "",
                networkPort: 0,
                connectionTransport: nil,
                authMethod: nil,
                emailProtocol: nil)
        }
        return theConnectInfo
    }

    private func notifyUnexpectedCallback(name: String) {
        let error = SmtpVerificationError.unexpected(name)
        verifiableAccountDelegate?.verified(
            verifier: self,
            basicConnectInfo: forcedConnectInfo(),
            result: .failure(error))
    }

    private func notify(error: Error) {
        verifiableAccountDelegate?.verified(
            verifier: self,
            basicConnectInfo: forcedConnectInfo(),
            result: .failure(error))
    }

    public func messageSent(_ smtp: SmtpSend, theNotification: Notification?) {
        notifyUnexpectedCallback(name: #function)
    }

    public func messageNotSent(_ smtp: SmtpSend, theNotification: Notification?) {
        notifyUnexpectedCallback(name: #function)
    }

    public func transactionInitiationCompleted(_ smtp: SmtpSend, theNotification: Notification?) {
        notifyUnexpectedCallback(name: #function)
    }

    public func transactionInitiationFailed(_ smtp: SmtpSend, theNotification: Notification?) {
        notifyUnexpectedCallback(name: #function)
    }

    public func recipientIdentificationCompleted(_ smtp: SmtpSend, theNotification: Notification?) {
        notifyUnexpectedCallback(name: #function)
    }

    public func recipientIdentificationFailed(_ smtp: SmtpSend, theNotification: Notification?) {
        notifyUnexpectedCallback(name: #function)
    }

    public func transactionResetCompleted(_ smtp: SmtpSend, theNotification: Notification?) {
        notifyUnexpectedCallback(name: #function)
    }

    public func transactionResetFailed(_ smtp: SmtpSend, theNotification: Notification?) {
        notifyUnexpectedCallback(name: #function)
    }

    public func authenticationCompleted(_ smtp: SmtpSend, theNotification: Notification?) {
    }

    public func authenticationFailed(_ smtp: SmtpSend, theNotification: Notification?) {
        notify(error: SmtpSendError.authenticationFailed(
            #function,
            forcedConnectInfo().accountEmailAddress))
    }

    public func connectionEstablished(_ smtp: SmtpSend, theNotification: Notification?) {}

    public func connectionLost(_ smtp: SmtpSend, theNotification: Notification?) {
        notify(error: SmtpSendError.connectionLost(#function))
    }

    public func connectionTerminated(_ smtp: SmtpSend, theNotification: Notification?) {
        notify(error: SmtpSendError.connectionTerminated(#function))
    }

    public func connectionTimedOut(_ smtp: SmtpSend, theNotification: Notification?) {
        notify(error: SmtpSendError.connectionTimedOut(#function))
    }

    public func badResponse(_ smtp: SmtpSend, response: String?) {
        notify(error: SmtpSendError.badResponse(#function))
    }

    public func requestCancelled(_ smtp: SmtpSend, theNotification: Notification?) {
        notifyUnexpectedCallback(name: #function)
    }

    public func serviceInitialized(_ smtp: SmtpSend, theNotification: Notification?) {
        // TODO: OK
        notifyUnexpectedCallback(name: #function)
    }

    public func serviceReconnected(_ smtp: SmtpSend, theNotification: Notification?) {
        notifyUnexpectedCallback(name: #function)
    }
}
