//
//  SMTPSendOperation.swift
//  pEp
//
//  Created by Andreas Buff on 05.07.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel

/// Does exactly one thing: Send a given message.
/// Does not create, modify, delete nor save messages.
/// Use for sending messages that should not be stored locally (i.e. exist in memory only).
class SMTPSendOperation: ConcurrentBaseOperation {
    /// Message to send
    private let message: Message
    private var smtpSendData: SmtpSendData

    private var smtpSend: SmtpSend? {
        let smtpSend = smtpSendData.smtp
        smtpSend?.delegate = self
        return smtpSend
    }

    init(parentName: String = #function,
         errorContainer: ServiceErrorProtocol,
         messageToSend: Message,
         smtpSendData: SmtpSendData) {
        self.message = messageToSend
        self.smtpSendData = smtpSendData
        super.init(parentName: parentName, errorContainer: errorContainer)
    }

    override public func main() {
        send()
    }

    private func send() {
        let pepDict = message.pEpMessageDict()
        let pantMail = PEPUtil.pantomime(pEpMessageDict: pepDict)
        guard let smtpSend = smtpSend else {
            Log.shared.errorAndCrash(component: #function, errorString: "No smtp")
            handleError(BackgroundError.GeneralError.illegalState(info: "No smtp"))
            return
        }
        smtpSend.smtp.setRecipients(nil)
        smtpSend.smtp.setMessageData(nil)
        smtpSend.smtp.setMessage(pantMail)
        smtpSend.smtp.sendMessage()
    }
}

extension SMTPSendOperation: SmtpSendDelegate {
    public func badResponse(_ smtp: SmtpSend, response: String?) {
        let error = BackgroundError.SmtpError.badResponse(info: comp)
        handleError(error, message: "badResponse")
    }

    public func messageSent(_ smtp: SmtpSend, theNotification: Notification?) {
        markAsFinished()
    }

    public func messageNotSent(_ smtp: SmtpSend, theNotification: Notification?) {
        let error = BackgroundError.SmtpError.messageNotSent(info: comp)
        handleError(error, message: "messageNotSent")
    }

    public func transactionInitiationCompleted(_ smtp: SmtpSend, theNotification: Notification?) {}

    public func transactionInitiationFailed(_ smtp: SmtpSend, theNotification: Notification?) {
        let error = BackgroundError.SmtpError.transactionInitiationFailed(info: comp)
        handleError(error, message: "transactionInitiationFailed")
    }

    public func recipientIdentificationCompleted(_ smtp: SmtpSend, theNotification: Notification?) {}

    public func recipientIdentificationFailed(_ smtp: SmtpSend, theNotification: Notification?) {
        let error = BackgroundError.SmtpError.recipientIdentificationFailed(info: comp)
        handleError(error, message: "recipientIdentificationFailed")
    }

    public func transactionResetCompleted(_ smtp: SmtpSend, theNotification: Notification?) {}

    public func transactionResetFailed(_ smtp: SmtpSend, theNotification: Notification?) {
        let error = BackgroundError.SmtpError.transactionResetFailed(info: comp)
        handleError(error, message: "transactionResetFailed")
    }

    public func authenticationCompleted(_ smtp: SmtpSend, theNotification: Notification?) {
        addError(BackgroundError.GeneralError.illegalState(info: #function))
        markAsFinished()
    }

    public func authenticationFailed(_ smtp: SmtpSend, theNotification: Notification?) {
        let error = BackgroundError.SmtpError.authenticationFailed(info: comp)
        handleError(error, message: "authenticationFailed")
    }

    public func connectionEstablished(_ smtp: SmtpSend, theNotification: Notification?) {}

    public func connectionLost(_ smtp: SmtpSend, theNotification: Notification?) {
        let error = BackgroundError.SmtpError.connectionLost(info: comp)
        handleError(error, message: "connectionLost")
    }

    public func connectionTerminated(_ smtp: SmtpSend, theNotification: Notification?) {
        let error = BackgroundError.SmtpError.connectionTerminated(info: comp)
        handleError(error, message: "connectionTerminated")
    }

    public func connectionTimedOut(_ smtp: SmtpSend, theNotification: Notification?) {
        let error = BackgroundError.SmtpError.connectionTimedOut(info: comp)
        handleError(error, message: "connectionTimedOut")
    }

    public func requestCancelled(_ smtp: SmtpSend, theNotification: Notification?) {
        let error = BackgroundError.SmtpError.requestCancelled(info: comp)
        handleError(error, message: "requestCancelled")
    }

    public func serviceInitialized(_ smtp: SmtpSend, theNotification: Notification?) {}

    public func serviceReconnected(_ smtp: SmtpSend, theNotification: Notification?) {}
}
