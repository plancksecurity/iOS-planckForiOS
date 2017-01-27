//
//  EncryptAndSendOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 11/01/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import CoreData

import MessageModel

/**
 Encrypts and SMTPs all suitable messages.
 */
open class EncryptAndSendOperation: ConcurrentBaseOperation {
    var smtpSend: SmtpSend!
    var smtpSendData: SmtpSendData
    lazy var session = PEPSession()

    /** The object ID of the last sent message, so we can change the sendStatus on success */
    var lastSentMessageObjectID: NSManagedObjectID?

    public init(smtpSendData: SmtpSendData, errorContainer: ServiceErrorProtocol = ErrorContainer()) {
        self.smtpSendData = smtpSendData
        super.init(errorContainer: errorContainer)
    }

    func checkSmtpSend() -> Bool {
        smtpSend = smtpSendData.smtp
        if smtpSend == nil {
            addError(Constants.errorSmtpInvalidConnection(component: comp))
            markAsFinished()
            return false
        }
        return true
    }

    override open func main() {
        if !shouldRun() {
            return
        }

        if !checkSmtpSend() {
            return
        }

        smtpSend.delegate = self
        handleNextMessage()
    }

    public static func retrieveNextMessage(
        context: NSManagedObjectContext) -> (PEPMessage, NSManagedObjectID)? {
        var pepMessage: PEPMessage?
        var objID: NSManagedObjectID?
        context.performAndWait {
            let p = NSPredicate(
                format: "uid = 0 and parent.folderType = %d and sendStatus = %d",
                FolderType.sent.rawValue, SendStatus.none.rawValue)
            if let m = CdMessage.first(with: p) {
                if m.sent == nil {
                    m.sent = NSDate()
                    Record.saveAndWait(context: context)
                }
                pepMessage = m.pEpMessage()
                objID = m.objectID
            }
        }
        if let o = objID, let p = pepMessage {
            return (p, o)
        }
        return nil
    }

    func send(pEpMessage: PEPMessage?) {
        guard let msg = pEpMessage else {
            handleError(Constants.errorInvalidParameter(comp), message: "Cannot send nil message")
            return
        }
        let pantMail = PEPUtil.pantomime(pEpMessage: msg)
        smtpSend.smtp.setRecipients(nil)
        smtpSend.smtp.setMessageData(nil)
        smtpSend.smtp.setMessage(pantMail)
        smtpSend.smtp.sendMessage()
    }

    func markLastSentMessageAsSent(context: NSManagedObjectContext) {
        if let objID = lastSentMessageObjectID {
            context.performAndWait {
                if let msg = context.object(with: objID) as? CdMessage {
                    msg.sendStatus = Int16(SendStatus.smtpDone.rawValue)
                    Log.info(component: #function,
                             content: "Setting \(msg.messageID): \(msg.sendStatus)")
                    Record.saveAndWait(context: context)
                } else {
                    Log.error(
                        component: self.comp, errorString: "Could not access sent message by ID")
                }
            }
        }
    }

    func handleNextMessage() {
        let context = Record.Context.background
        markLastSentMessageAsSent(context: context)

        lastSentMessageObjectID = nil
        if let (msg, objID) = EncryptAndSendOperation.retrieveNextMessage(context: context) {
            lastSentMessageObjectID = objID
            let (status, encMsg) = session.encrypt(pEpMessageDict: msg)
            let (encMsg2, error) = PEPUtil.check(
                comp: comp, status: status, encryptedMessage: encMsg)
            if let err = error {
                Log.error(component: comp, error: err)
                send(pEpMessage: encMsg as? PEPMessage)
            } else {
                send(pEpMessage: encMsg2 as? PEPMessage)
            }
        } else {
            markAsFinished()
        }
    }
}

extension EncryptAndSendOperation: SmtpSendDelegate {
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
        addError(Constants.errorIllegalState(comp, stateName: "authenticationCompleted"))
        markAsFinished()
    }

    public func authenticationFailed(_ smtp: SmtpSend, theNotification: Notification?) {
        let error = Constants.errorSmtp(comp, code: Constants.SmtpErrorCode.authenticationFailed)
        handleError(error, message: "authenticationFailed")
    }

    public func connectionEstablished(_ smtp: SmtpSend, theNotification: Notification?) {}

    public func connectionLost(_ smtp: SmtpSend, theNotification: Notification?) {
        let error = Constants.errorSmtp(comp, code: Constants.SmtpErrorCode.connectionLost)
        handleError(error, message: "connectionLost")
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
