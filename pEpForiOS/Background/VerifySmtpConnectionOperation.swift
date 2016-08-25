//
//  VerifySmtpConnectionOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 29/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation

class VerifySmtpConnectionOperation: VerifyServiceOperation {
    let errorDomain = "VerifySmtpConnectionOperation"

    override func main() {
        if self.cancelled {
            return
        }
        service = connectionManager.smtpConnection(connectInfo)
        (service as! SmtpSend).delegate = self
        service.start()
    }
}

extension VerifySmtpConnectionOperation: SmtpSendDelegate {
    func messageSent(smtp: SmtpSend, theNotification: NSNotification?) {}
    func messageNotSent(smtp: SmtpSend, theNotification: NSNotification?) {}
    func transactionInitiationCompleted(smtp: SmtpSend, theNotification: NSNotification?) {}
    func transactionInitiationFailed(smtp: SmtpSend, theNotification: NSNotification?) {}
    func recipientIdentificationCompleted(smtp: SmtpSend, theNotification: NSNotification?) {}
    func recipientIdentificationFailed(smtp: SmtpSend, theNotification: NSNotification?) {}
    func transactionResetCompleted(smtp: SmtpSend, theNotification: NSNotification?) {}
    func transactionResetFailed(smtp: SmtpSend, theNotification: NSNotification?) {}

    func authenticationCompleted(smtp: SmtpSend, theNotification: NSNotification?) {
        self.isFinishing = true
        close(true)
    }

    func authenticationFailed(smtp: SmtpSend, theNotification: NSNotification?) {
        if !isFinishing {
            errors.append(Constants.errorAuthenticationFailed(errorDomain))
            close(true)
        }
    }

    func connectionEstablished(smtp: SmtpSend, theNotification: NSNotification?) {}

    func connectionLost(smtp: SmtpSend, theNotification: NSNotification?) {
        if !isFinishing {
            errors.append(Constants.errorConnectionLost(errorDomain))
            isFinishing = true
            markAsFinished()
        }
    }

    func connectionTerminated(smtp: SmtpSend, theNotification: NSNotification?) {
        if !isFinishing {
            errors.append(Constants.errorConnectionTerminated(errorDomain))
            isFinishing = true
            markAsFinished()
        }
    }

    func connectionTimedOut(smtp: SmtpSend, theNotification: NSNotification?) {
        if !isFinishing {
            errors.append(Constants.errorTimeout(errorDomain))
            isFinishing = true
            markAsFinished()
        }
    }

    func requestCancelled(smtp: SmtpSend, theNotification: NSNotification?) {}
    func serviceInitialized(smtp: SmtpSend, theNotification: NSNotification?) {}
    func serviceReconnected(smtp: SmtpSend, theNotification: NSNotification?) {}
}