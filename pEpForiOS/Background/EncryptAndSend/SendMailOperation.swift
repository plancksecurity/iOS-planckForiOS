//
//  SendMailOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 23/06/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit
import CoreData

public class SendMailOperation: ConcurrentBaseOperation {
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

    override public func main() {
        let privateMOC = encryptionData.coreDataUtil.privateContext()
        var connectInfo: ConnectInfo? = nil
        privateMOC.performBlock() {
            let model = Model.init(context: privateMOC)
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

            guard let outFolder = model.folderByType(.LocalOutbox, email: account.email) else {
                let error = Constants.errorInvalidParameter(
                    self.comp, errorMessage: NSLocalizedString("Could not access outbox",
                        comment: "Internal error"))
                self.handleEntryError(error, message: "Could not access outbox")
                return
            }

            guard let message = privateMOC.objectWithID(
                self.encryptionData.coreDataMessageID) as? Message else {
                    let error = Constants.errorInvalidParameter(
                        self.comp,
                        errorMessage:
                        NSLocalizedString("Email for encryption could not be accessed",
                            comment: "Error message when message to encrypt could not be found."))
                    self.handleEntryError(error,
                        message: "Email for encryption could not be accessed")
                    return
            }

            message.folder = outFolder as! Folder
            CoreDataUtil.saveContext(managedObjectContext: privateMOC)

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
    func handleEntryError(error: NSError, message: String) {
        handleError(error, message: message)
    }

    func handleError(error: NSError, message: String) {
        addError(error)
        Log.errorComponent(comp, errorString: message, error: error)
        markAsFinished()
    }
}

extension SendMailOperation: SmtpSendDelegate {
    public func messageSent(smtp: SmtpSend, theNotification: NSNotification?) {
        handleNextMail()
    }

    public func messageNotSent(smtp: SmtpSend, theNotification: NSNotification?) {
        let error = Constants.errorSmtp(comp, code: Constants.SmtpErrorCode.MessageNotSent)
        handleError(error, message: "messageNotSent")
    }

    public func transactionInitiationCompleted(smtp: SmtpSend, theNotification: NSNotification?) {}

    public func transactionInitiationFailed(smtp: SmtpSend, theNotification: NSNotification?) {
        let error = Constants.errorSmtp(comp,
                                        code: Constants.SmtpErrorCode.TransactionInitiationFailed)
        handleError(error, message: "transactionInitiationFailed")
    }

    public func recipientIdentificationCompleted(smtp: SmtpSend, theNotification: NSNotification?) {}

    public func recipientIdentificationFailed(smtp: SmtpSend, theNotification: NSNotification?) {
        let error = Constants.errorSmtp(comp,
                                        code: Constants.SmtpErrorCode.RecipientIdentificationFailed)
        handleError(error, message: "recipientIdentificationFailed")
    }

    public func transactionResetCompleted(smtp: SmtpSend, theNotification: NSNotification?) {}

    public func transactionResetFailed(smtp: SmtpSend, theNotification: NSNotification?) {
        let error = Constants.errorSmtp(comp, code: Constants.SmtpErrorCode.TransactionResetFailed)
        handleError(error, message: "transactionResetFailed")
    }

    public func authenticationCompleted(smtp: SmtpSend, theNotification: NSNotification?) {
        handleNextMail()
    }

    public func authenticationFailed(smtp: SmtpSend, theNotification: NSNotification?) {
        let error = Constants.errorSmtp(comp, code: Constants.SmtpErrorCode.AuthenticationFailed)
        handleError(error, message: "authenticationFailed")
    }

    public func connectionEstablished(smtp: SmtpSend, theNotification: NSNotification?) {}

    public func connectionLost(smtp: SmtpSend, theNotification: NSNotification?) {
        let error = Constants.errorSmtp(comp, code: Constants.SmtpErrorCode.ConnectionLost)
        handleError(error, message: "connectionEstablished")
    }

    public func connectionTerminated(smtp: SmtpSend, theNotification: NSNotification?) {
        let error = Constants.errorSmtp(comp, code: Constants.SmtpErrorCode.ConnectionTerminated)
        handleError(error, message: "connectionTerminated")
    }

    public func connectionTimedOut(smtp: SmtpSend, theNotification: NSNotification?) {
        let error = Constants.errorSmtp(comp, code: Constants.SmtpErrorCode.ConnectionTimedOut)
        handleError(error, message: "connectionTimedOut")
    }

    public func requestCancelled(smtp: SmtpSend, theNotification: NSNotification?) {
        let error = Constants.errorSmtp(comp, code: Constants.SmtpErrorCode.RequestCancelled)
        handleError(error, message: "requestCancelled")
    }

    public func serviceInitialized(smtp: SmtpSend, theNotification: NSNotification?) {}

    public func serviceReconnected(smtp: SmtpSend, theNotification: NSNotification?) {}
}