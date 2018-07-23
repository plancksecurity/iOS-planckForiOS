//
//  LoginSmtpOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 29/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import MessageModel

public class LoginSmtpOperation: ConcurrentBaseOperation {
    var service: SmtpSend!
    var smtpSendData: SmtpSendData

    public init(parentName: String = #function,
                smtpSendData: SmtpSendData,
                errorContainer: ServiceErrorProtocol = ErrorContainer()) {
        self.smtpSendData = smtpSendData
        super.init(parentName: parentName, errorContainer: errorContainer)
    }

    override public func main() {
        if isCancelled {
            markAsFinished()
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
        let context = Record.Context.background
        context.perform {
//            if let err = self.smtpSendData.connectInfo.unsetNeedsVerificationAndFinish( //IOS-1033: cleanup.
//                context: context) {
//                self.addError(err)
//            }
            self.markAsFinished()
        }
    }

    public func authenticationFailed(_ smtp: SmtpSend, theNotification: Notification?) {
        addError(SmtpSendError.authenticationFailed(#function))
        markAsFinished()
    }

    public func connectionEstablished(_ smtp: SmtpSend, theNotification: Notification?) {}

    public func connectionLost(_ smtp: SmtpSend, theNotification: Notification?) {
        addError(SmtpSendError.connectionLost(#function))
        markAsFinished()
    }

    public func connectionTerminated(_ smtp: SmtpSend, theNotification: Notification?) {
        addError(SmtpSendError.connectionTerminated(#function))
        markAsFinished()
    }

    public func connectionTimedOut(_ smtp: SmtpSend, theNotification: Notification?) {
        addError(SmtpSendError.connectionTimedOut(#function))
        markAsFinished()
    }

    public func badResponse(_ smtp: SmtpSend, response: String?) {
        addError(SmtpSendError.badResponse(#function))
        markAsFinished()
    }

    public func requestCancelled(_ smtp: SmtpSend, theNotification: Notification?) {}
    public func serviceInitialized(_ smtp: SmtpSend, theNotification: Notification?) {}
    public func serviceReconnected(_ smtp: SmtpSend, theNotification: Notification?) {}
}
