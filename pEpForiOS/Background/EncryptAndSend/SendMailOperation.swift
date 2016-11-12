//
//  SendMailOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 23/06/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit
import CoreData

import MessageModel

open class SendMailOperation: ConcurrentBaseOperation {
    let comp = "SendMailOperation"

    /**
     All the parameters for the operation come from here.
     `mailsToSend` denotes the (pEp) mails that are about to be sent.
     */
    let encryptionData: EncryptionData

    /**
     Store the SMTP object so that it does not get collected away.
     */
    var smtpSend: SmtpSend!

    /**
     The mail currently under processing (send).
     */
    var currentPepMailToSend: PEPMail? = nil

    public init(encryptionData: EncryptionData) {
        self.encryptionData = encryptionData
    }

    override open func main() {
        let privateMOC = encryptionData.coreDataUtil.privateContext()
        var connectInfo: EmailConnectInfo? = nil
        privateMOC.perform() {
            let model = CdModel.init(context: privateMOC)
            guard let account = model.accountByEmail(self.encryptionData.accountEmail) else {
                self.handleEntryError(Constants.errorInvalidParameter(
                    self.comp,
                    errorMessage: String.localizedStringWithFormat(
                        NSLocalizedString("Could not get account by email: '%s'",
                            comment: "Error message when account could not be retrieved"),
                        self.encryptionData.accountEmail)),
                    message: "Could not get account by email: \(self.encryptionData.accountEmail)")
                return
            }
            connectInfo = account.connectInfo

            guard let outFolder = model.folderByType(.localOutbox, email: account.connectInfo.userName) else {
                let error = Constants.errorInvalidParameter(
                    self.comp, errorMessage: NSLocalizedString("Could not access outbox",
                        comment: "Internal error"))
                self.handleEntryError(error, message: "Could not access outbox")
                return
            }

            guard let message = privateMOC.object(
                with: self.encryptionData.coreDataMessageID) as? CdMessage else {
                    let error = Constants.errorInvalidParameter(
                        self.comp,
                        errorMessage:
                        NSLocalizedString("Email for encryption could not be accessed",
                            comment: "Error message when message to encrypt could not be found."))
                    self.handleEntryError(error,
                        message: "Email for encryption could not be accessed")
                    return
            }

            message.folder = outFolder
            CoreDataUtil.saveContext(privateMOC)

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

    /**
     Indicates an error setting up the operation. For now, this is handled
     the same as any other error, but that might change.
     */
    func handleEntryError(_ error: NSError, message: String) {
        handleError(error, message: message)
    }

    func handleError(_ error: NSError, message: String) {
        addError(error)
        Log.error(component: comp, errorString: message, error: error)
        markAsFinished()
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
