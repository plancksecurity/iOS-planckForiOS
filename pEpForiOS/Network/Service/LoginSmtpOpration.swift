//
//  LoginSmtpOpration.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 29/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

class LoginSmtpOpration: ConcurrentBaseOperation {
    var service: SmtpSend!
    var smtpSendData: SmtpSendData

    init(smtpSendData: SmtpSendData, errorContainer: ErrorProtocol = ErrorContainer()) {
        self.smtpSendData = smtpSendData
        super.init(errorContainer: errorContainer)
    }

    override func main() {
        if self.isCancelled {
            return
        }
        service = SmtpSend(connectInfo: smtpSendData.connectInfo)
        service.delegate = self
        service.start()
    }
}

extension LoginSmtpOpration: SmtpSendDelegate {
    func messageSent(_ smtp: SmtpSend, theNotification: Notification?) {}
    func messageNotSent(_ smtp: SmtpSend, theNotification: Notification?) {}
    func transactionInitiationCompleted(_ smtp: SmtpSend, theNotification: Notification?) {}
    func transactionInitiationFailed(_ smtp: SmtpSend, theNotification: Notification?) {}
    func recipientIdentificationCompleted(_ smtp: SmtpSend, theNotification: Notification?) {}
    func recipientIdentificationFailed(_ smtp: SmtpSend, theNotification: Notification?) {}
    func transactionResetCompleted(_ smtp: SmtpSend, theNotification: Notification?) {}
    func transactionResetFailed(_ smtp: SmtpSend, theNotification: Notification?) {}

    func authenticationCompleted(_ smtp: SmtpSend, theNotification: Notification?) {
        markAsFinished()
    }

    func authenticationFailed(_ smtp: SmtpSend, theNotification: Notification?) {
        addError(Constants.errorAuthenticationFailed(comp))
        markAsFinished()
    }

    func connectionEstablished(_ smtp: SmtpSend, theNotification: Notification?) {}

    func connectionLost(_ smtp: SmtpSend, theNotification: Notification?) {
        addError(Constants.errorConnectionLost(comp))
        markAsFinished()
    }

    func connectionTerminated(_ smtp: SmtpSend, theNotification: Notification?) {
        addError(Constants.errorConnectionTerminated(comp))
        markAsFinished()
    }

    func connectionTimedOut(_ smtp: SmtpSend, theNotification: Notification?) {
        addError(Constants.errorTimeout(comp))
        markAsFinished()
    }

    func requestCancelled(_ smtp: SmtpSend, theNotification: Notification?) {}
    func serviceInitialized(_ smtp: SmtpSend, theNotification: Notification?) {}
    func serviceReconnected(_ smtp: SmtpSend, theNotification: Notification?) {}
}
