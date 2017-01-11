//
//  EncryptAndSendOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 11/01/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit

/**
 Encrypts and SMTPs all suitable messages.
 Currently, that means all messages with a UID of 0 in the Sent folder.
 */
class EncryptAndSendOperation: ConcurrentBaseOperation {
    var smtpSend: SmtpSend!
    var smtpSendData: SmtpSendData

    init(smtpSendData: SmtpSendData, errorContainer: ErrorProtocol = ErrorContainer()) {
        self.smtpSendData = smtpSendData
        super.init(errorContainer: errorContainer)
    }

    func checkSmtpSend() -> Bool {
        smtpSend = smtpSendData.smtp
        if smtpSend == nil {
            addError(Constants.errorSmtpInvalidConnection(component: comp))
            markAsFinished()
            return false
        }
        return true
    }

    override open func main() {
        if !shouldRun() {
            return
        }

        if !checkSmtpSend() {
            return
        }

        smtpSend.delegate = self
        smtpSend.start()
    }

    func handleNextMessage() {
    }
}

extension EncryptAndSendOperation: SmtpSendDelegate {
    public func messageSent(_ smtp: SmtpSend, theNotification: Notification?) {
        handleNextMessage()
    }

    public func messageNotSent(_ smtp: SmtpSend, theNotification: Notification?) {
        let error = Constants.errorSmtp(comp, code: Constants.SmtpErrorCode.messageNotSent)
        handleError(error, message: "messageNotSent")
    }

    public func transactionInitiationCompleted(_ smtp: SmtpSend, theNotification: Notification?) {}

    public func transactionInitiationFailed(_ smtp: SmtpSend, theNotification: Notification?) {
        let error = Constants.errorSmtp(comp,
                                        code: Constants.SmtpErrorCode.transactionInitiationFailed)
        handleError(error, message: "transactionInitiationFailed")
    }

    public func recipientIdentificationCompleted(_ smtp: SmtpSend, theNotification: Notification?) {}

    public func recipientIdentificationFailed(_ smtp: SmtpSend, theNotification: Notification?) {
        let error = Constants.errorSmtp(comp,
                                        code: Constants.SmtpErrorCode.recipientIdentificationFailed)
        handleError(error, message: "recipientIdentificationFailed")
    }

    public func transactionResetCompleted(_ smtp: SmtpSend, theNotification: Notification?) {}

    public func transactionResetFailed(_ smtp: SmtpSend, theNotification: Notification?) {
        let error = Constants.errorSmtp(comp, code: Constants.SmtpErrorCode.transactionResetFailed)
        handleError(error, message: "transactionResetFailed")
    }

    public func authenticationCompleted(_ smtp: SmtpSend, theNotification: Notification?) {
        handleNextMessage()
    }

    public func authenticationFailed(_ smtp: SmtpSend, theNotification: Notification?) {
        let error = Constants.errorSmtp(comp, code: Constants.SmtpErrorCode.authenticationFailed)
        handleError(error, message: "authenticationFailed")
    }

    public func connectionEstablished(_ smtp: SmtpSend, theNotification: Notification?) {}

    public func connectionLost(_ smtp: SmtpSend, theNotification: Notification?) {
        let error = Constants.errorSmtp(comp, code: Constants.SmtpErrorCode.connectionLost)
        handleError(error, message: "connectionEstablished")
    }

    public func connectionTerminated(_ smtp: SmtpSend, theNotification: Notification?) {
        let error = Constants.errorSmtp(comp, code: Constants.SmtpErrorCode.connectionTerminated)
        handleError(error, message: "connectionTerminated")
    }

    public func connectionTimedOut(_ smtp: SmtpSend, theNotification: Notification?) {
        let error = Constants.errorSmtp(comp, code: Constants.SmtpErrorCode.connectionTimedOut)
        handleError(error, message: "connectionTimedOut")
    }

    public func requestCancelled(_ smtp: SmtpSend, theNotification: Notification?) {
        let error = Constants.errorSmtp(comp, code: Constants.SmtpErrorCode.requestCancelled)
        handleError(error, message: "requestCancelled")
    }

    public func serviceInitialized(_ smtp: SmtpSend, theNotification: Notification?) {}

    public func serviceReconnected(_ smtp: SmtpSend, theNotification: Notification?) {}
}
