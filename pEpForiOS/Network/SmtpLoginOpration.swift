//
//  VerifySmtpConnectionOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 29/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

class VerifySmtpConnectionOperation: VerifyServiceOperation {
    let errorDomain = "VerifySmtpConnectionOperation"

    override func main() {
        if self.isCancelled {
            return
        }
        service = connectionManager.smtpConnection(connectInfo: connectInfo)
        (service as! SmtpSend).delegate = self
        service.start()
    }
}

extension VerifySmtpConnectionOperation: SmtpSendDelegate {
    func messageSent(_ smtp: SmtpSend, theNotification: Notification?) {}
    func messageNotSent(_ smtp: SmtpSend, theNotification: Notification?) {}
    func transactionInitiationCompleted(_ smtp: SmtpSend, theNotification: Notification?) {}
    func transactionInitiationFailed(_ smtp: SmtpSend, theNotification: Notification?) {}
    func recipientIdentificationCompleted(_ smtp: SmtpSend, theNotification: Notification?) {}
    func recipientIdentificationFailed(_ smtp: SmtpSend, theNotification: Notification?) {}
    func transactionResetCompleted(_ smtp: SmtpSend, theNotification: Notification?) {}
    func transactionResetFailed(_ smtp: SmtpSend, theNotification: Notification?) {}

    func authenticationCompleted(_ smtp: SmtpSend, theNotification: Notification?) {
        self.isFinishing = true
        close(true)
    }

    func authenticationFailed(_ smtp: SmtpSend, theNotification: Notification?) {
        if !isFinishing {
            errors.append(Constants.errorAuthenticationFailed(errorDomain))
            close(true)
        }
    }

    func connectionEstablished(_ smtp: SmtpSend, theNotification: Notification?) {}

    func connectionLost(_ smtp: SmtpSend, theNotification: Notification?) {
        if !isFinishing {
            errors.append(Constants.errorConnectionLost(errorDomain))
            isFinishing = true
            markAsFinished()
        }
    }

    func connectionTerminated(_ smtp: SmtpSend, theNotification: Notification?) {
        if !isFinishing {
            errors.append(Constants.errorConnectionTerminated(errorDomain))
            isFinishing = true
            markAsFinished()
        }
    }

    func connectionTimedOut(_ smtp: SmtpSend, theNotification: Notification?) {
        if !isFinishing {
            errors.append(Constants.errorTimeout(errorDomain))
            isFinishing = true
            markAsFinished()
        }
    }

    func requestCancelled(_ smtp: SmtpSend, theNotification: Notification?) {}
    func serviceInitialized(_ smtp: SmtpSend, theNotification: Notification?) {}
    func serviceReconnected(_ smtp: SmtpSend, theNotification: Notification?) {}
}
