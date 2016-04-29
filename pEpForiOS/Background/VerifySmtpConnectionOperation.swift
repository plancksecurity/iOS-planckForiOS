//
//  VerifySmtpConnectionOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 29/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation

class VerifySmtpConnectionOperation: BaseOperation {
    let errorDomain = "VerifySmtpConnectionOperation"

    let connectInfo: ConnectInfo
    var smtp: SmtpSend!

    init(grandOperator: IGrandOperator, connectInfo: ConnectInfo) {
        self.connectInfo = connectInfo
        super.init(grandOperator: grandOperator)
    }

    override func main() {
        if self.cancelled {
            return
        }
        smtp = grandOperator.connectionManager.smtpConnection(connectInfo)
        smtp.delegate = self
        smtp.start()
    }
}

extension VerifySmtpConnectionOperation: SmtpSendDelegate {
    func messageSent(smtp: SmtpSend, theNotification: NSNotification!) {}
    func messageNotSent(smtp: SmtpSend, theNotification: NSNotification!) {}
    func transactionInitiationCompleted(smtp: SmtpSend, theNotification: NSNotification!) {}
    func transactionInitiationFailed(smtp: SmtpSend, theNotification: NSNotification!) {}
    func recipientIdentificationCompleted(smtp: SmtpSend, theNotification: NSNotification!) {}
    func recipientIdentificationFailed(smtp: SmtpSend, theNotification: NSNotification!) {}
    func transactionResetCompleted(smtp: SmtpSend, theNotification: NSNotification!) {}
    func transactionResetFailed(smtp: SmtpSend, theNotification: NSNotification!) {}

    func authenticationCompleted(smtp: SmtpSend, theNotification: NSNotification!) {
        markAsFinished()
    }

    func authenticationFailed(smtp: SmtpSend, theNotification: NSNotification!) {
        grandOperator.setErrorForOperation(self,
                                           error: Constants.errorAuthenticationFailed(errorDomain))
        markAsFinished()
    }

    func connectionEstablished(smtp: SmtpSend, theNotification: NSNotification!) {}

    func connectionLost(smtp: SmtpSend, theNotification: NSNotification!) {
        grandOperator.setErrorForOperation(self, error: Constants.errorConnectionLost(errorDomain))
        markAsFinished()
    }

    func connectionTerminated(smtp: SmtpSend, theNotification: NSNotification!) {
        grandOperator.setErrorForOperation(self,
                                           error: Constants.errorConnectionTerminated(errorDomain))
        markAsFinished()
    }

    func connectionTimedOut(smtp: SmtpSend, theNotification: NSNotification!) {
        grandOperator.setErrorForOperation(self, error: Constants.errorTimeout(errorDomain))
        markAsFinished()
    }

    func requestCancelled(smtp: SmtpSend, theNotification: NSNotification!) {}
    func serviceInitialized(smtp: SmtpSend, theNotification: NSNotification!) {}
    func serviceReconnected(smtp: SmtpSend, theNotification: NSNotification!) {}
}

