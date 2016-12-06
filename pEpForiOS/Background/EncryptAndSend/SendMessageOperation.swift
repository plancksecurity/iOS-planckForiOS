//
//  SendMessageOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 23/06/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import MessageModel

open class SendMessageOperation: EncryptBaseOperation {
    /**
     Store the SMTP object so that it does not get collected away.
     */
    var smtpSend: SmtpSend!

    /**
     The message currently under processing (send).
     */
    var currentPepMessageToSend: PEPMessage? = nil

    public init(encryptionData: EncryptionData) {
        super.init(comp: "SendMessageOperation", encryptionData: encryptionData)
    }

    override open func main() {
        smtpSend = encryptionData.connectionManager.smtpConnection(
            connectInfo: encryptionData.smtpConnectInfo)
        smtpSend.delegate = self
        smtpSend.start()
    }

    func sendNextMessageOrMarkAsFinished() {
        if encryptionData.messagesToSend.count > 0 {
            currentPepMessageToSend = encryptionData.messagesToSend.removeLast()
            // pantMail for e-mail message
            let pantMail = PEPUtil.pantomime(pEpMessage: currentPepMessageToSend!)
            smtpSend.smtp.setRecipients(nil)
            smtpSend.smtp.setMessageData(nil)
            smtpSend.smtp.setMessage(pantMail)
            smtpSend.smtp.sendMessage()
            return
        }
        // No messages left
        markAsFinished()
    }

    func handleNextMessage() {
        if let lastSentMessage = currentPepMessageToSend {
            encryptionData.messagesSent.append(lastSentMessage)
        }
        sendNextMessageOrMarkAsFinished()
    }
}

extension SendMessageOperation: SmtpSendDelegate {
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
