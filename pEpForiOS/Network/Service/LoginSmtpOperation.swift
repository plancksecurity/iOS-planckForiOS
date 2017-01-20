//
//  LoginSmtpOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 29/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

open class LoginSmtpOperation: ConcurrentBaseOperation {
    var service: SmtpSend!
    var smtpSendData: SmtpSendData

    public init(smtpSendData: SmtpSendData, errorContainer: ServiceErrorProtocol = ErrorContainer()) {
        self.smtpSendData = smtpSendData
        super.init(errorContainer: errorContainer)
    }

    override open func main() {
        if self.isCancelled {
            return
        }
        service = SmtpSend(connectInfo: smtpSendData.connectInfo)
        service.delegate = self
        service.start()
    }
}

extension LoginSmtpOperation: SmtpSendDelegate {
    public func messageSent(_ smtp: SmtpSend, theNotification: Notification?) {}
    public func messageNotSent(_ smtp: SmtpSend, theNotification: Notification?) {}
    public func transactionInitiationCompleted(_ smtp: SmtpSend, theNotification: Notification?) {}
    public func transactionInitiationFailed(_ smtp: SmtpSend, theNotification: Notification?) {}
    public func recipientIdentificationCompleted(_ smtp: SmtpSend, theNotification: Notification?) {}
    public func recipientIdentificationFailed(_ smtp: SmtpSend, theNotification: Notification?) {}
    public func transactionResetCompleted(_ smtp: SmtpSend, theNotification: Notification?) {}
    public func transactionResetFailed(_ smtp: SmtpSend, theNotification: Notification?) {}

    public func authenticationCompleted(_ smtp: SmtpSend, theNotification: Notification?) {
        smtpSendData.smtp = smtp
        markAsFinished()
    }

    public func authenticationFailed(_ smtp: SmtpSend, theNotification: Notification?) {
        addError(Constants.errorAuthenticationFailed(comp))
        markAsFinished()
    }

    public func connectionEstablished(_ smtp: SmtpSend, theNotification: Notification?) {}

    public func connectionLost(_ smtp: SmtpSend, theNotification: Notification?) {
        addError(Constants.errorConnectionLost(comp))
        markAsFinished()
    }

    public func connectionTerminated(_ smtp: SmtpSend, theNotification: Notification?) {
        addError(Constants.errorConnectionTerminated(comp))
        markAsFinished()
    }

    public func connectionTimedOut(_ smtp: SmtpSend, theNotification: Notification?) {
        addError(Constants.errorTimeout(comp))
        markAsFinished()
    }

    public func requestCancelled(_ smtp: SmtpSend, theNotification: Notification?) {}
    public func serviceInitialized(_ smtp: SmtpSend, theNotification: Notification?) {}
    public func serviceReconnected(_ smtp: SmtpSend, theNotification: Notification?) {}
}
