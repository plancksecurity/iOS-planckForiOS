//
//  SendMailOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 23/06/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import CoreData

import MessageModel

open class SendMailOperation: EncryptBaseOperation {
    /**
     Store the SMTP object so that it does not get collected away.
     */
    var smtpSend: SmtpSend!

    /**
     The mail currently under processing (send).
     */
    var currentPepMailToSend: PEPMail? = nil

    public init(encryptionData: EncryptionData) {
        super.init(comp: "SendMailOperation", encryptionData: encryptionData)
    }

    override open func main() {
        let privateMOC = encryptionData.coreDataUtil.privateContext()
        var connectInfo: EmailConnectInfo? = nil
        privateMOC.perform() {
            guard let message = self.fetchMessage(context: privateMOC) else {
                return
            }

            guard let account = message.parent?.account else {
                self.addError(Constants.errorCannotFindAccount(component: self.comp))
                return
            }
            connectInfo = account.connectInfo

            Record.saveAndWait(context: privateMOC)

            if let ci = connectInfo {
                self.smtpSend = self.encryptionData.connectionManager.smtpConnection(ci)
                self.smtpSend.delegate = self
                self.smtpSend.start()
            } else {
                self.markAsFinished()
            }
        }
    }

    func sendNextMailOrMarkAsFinished() {
        if encryptionData.mailsToSend.count > 0 {
            currentPepMailToSend = encryptionData.mailsToSend.removeLast()
            let pantMail = PEPUtil.pantomimeMailFromPep(currentPepMailToSend!)
            smtpSend.smtp.setRecipients(nil)
            smtpSend.smtp.setMessageData(nil)
            smtpSend.smtp.setMessage(pantMail)
            smtpSend.smtp.sendMessage()
            return
        }
        // No emails left
        markAsFinished()
    }

    func handleNextMail() {
        if let lastSentMail = currentPepMailToSend {
            encryptionData.mailsSent.append(lastSentMail)
        }
        sendNextMailOrMarkAsFinished()
    }
}

extension SendMailOperation: SmtpSendDelegate {
    public func messageSent(_ smtp: SmtpSend, theNotification: Notification?) {
        handleNextMail()
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
        handleNextMail()
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
