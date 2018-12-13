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
public class EncryptAndSendOperation: ConcurrentBaseOperation {
    var smtpSend: SmtpSend!
    var smtpSendData: SmtpSendData

    /** The object ID of the last sent message, so we can move it on success */
    var lastSentMessageObjectID: NSManagedObjectID?

    public init(parentName: String = #function, smtpSendData: SmtpSendData,
                errorContainer: ServiceErrorProtocol = ErrorContainer()) {
        self.smtpSendData = smtpSendData
        super.init(parentName: parentName, errorContainer: errorContainer)
    }

    private func checkSmtpSend() -> Bool {
        smtpSend = smtpSendData.smtp
        if smtpSend == nil {
            addError(BackgroundError.SmtpError.invalidConnection(info: comp))
            markAsFinished()
            return false
        }
        return true
    }

    override public func main() {
        if !checkSmtpSend() {
            markAsFinished()
            return
        }
        smtpSend.delegate = self
        handleNextMessage()
    }

    private static func outgoingMails(context: NSManagedObjectContext,
                                     cdAccount: CdAccount) -> [CdMessage] {
        let p = CdMessage.PredicateFactory.outgoingMails(in: cdAccount)
        return CdMessage.all(predicate: p, in: context) as? [CdMessage] ?? []
    }

    static func outgoingMailsExist(in context: NSManagedObjectContext,
                                   forAccountWith cdAccountObjectId: NSManagedObjectID) -> Bool {
        var outgoingMsgs = [CdMessage]()
        context.performAndWait {
            guard let cdAccount = context.object(with: cdAccountObjectId) as? CdAccount else {
                Log.shared.errorAndCrash(component: #function,
                                         errorString: "No NSManagedObject for NSManagedObjectID")
                outgoingMsgs = []
                return
            }
            outgoingMsgs = outgoingMails(context: context, cdAccount: cdAccount)
        }
        return outgoingMsgs.count > 0
    }

    public static func retrieveNextMessage(
        context: NSManagedObjectContext,
        cdAccount: CdAccount) -> (PEPMessageDict, Bool, NSManagedObjectID)? {
        var pepMessage: PEPMessageDict?
        var objID: NSManagedObjectID?
        var protected = true

        let p = CdMessage.PredicateFactory.outgoingMails(in: cdAccount)
        if let m = CdMessage.first(predicate: p) {
            if m.sent == nil {
                m.sent = Date()
                context.saveAndLogErrors()
            }
            pepMessage = m.pEpMessageDict()
            protected = m.pEpProtected
            objID = m.objectID
        }

        if let o = objID, let p = pepMessage {
            return (p, protected, o)
        }
        return nil
    }

    func send(pEpMessageDict: PEPMessageDict?) {
        guard var msg = pEpMessageDict else {
            handleError(BackgroundError.GeneralError.invalidParameter(info: comp),
                        message: "Cannot send nil message")
            return
        }

        msg.removeOriginalRatingHeader()

        let pantMail = PEPUtil.pantomime(pEpMessageDict: msg)
        smtpSend.smtp.setRecipients(nil)
        smtpSend.smtp.setMessageData(nil)
        smtpSend.smtp.setMessage(pantMail)
        smtpSend.smtp.sendMessage()
    }

    func moveLastMessageToSentFolder(context: NSManagedObjectContext) {
        guard
            let objID = lastSentMessageObjectID,
            let cdMessage = context.object(with: objID) as? CdMessage,
            let cdAccount = cdMessage.parent?.account,
            let sentFolder = CdFolder.by(folderType: .sent, account: cdAccount),
            let message = cdMessage.message()
            else {
                Log.shared.errorAndCrash(component: #function,
                                         errorString: "Problem moving last message")
                return
        }
        let rating = message.outgoingMessageRating().rawValue
        MessageModelConfig.messageFolderDelegate?.didDelete(messageFolder: message,
                                                            belongingToThread: Set())
        cdMessage.parent = sentFolder
        cdMessage.imap?.localFlags?.flagSeen = true
        cdMessage.pEpRating = Int16(rating)
        Record.saveAndWait()

        guard let refreshedMsg = cdMessage.message() else {
            Log.shared.errorAndCrash(component: #function, errorString: "No msg")
            return
        }
        Message.createCdFakeMessage(for: refreshedMsg)
        Log.info(component: #function,
                 content: "Sent message. messageID: \(String(describing: cdMessage.messageID))")
    }

    func handleNextMessage() {
        guard !isCancelled else {
            waitForBackgroundTasksToFinish()
            return
        }
        let context = privateMOC
        context.perform { [weak self] in
            self?.handleNextMessageInternal(context: context)
        }
    }

    private func handleMessageSent() {
        let moc = privateMOC
        moc.perform { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash(component: #function, errorString: "Lost myself")
                return
            }
            me.moveLastMessageToSentFolder(context: moc)
            me.handleNextMessageInternal(context: moc)
        }
    }

    func handleNextMessageInternal(context: NSManagedObjectContext) {
        guard
            let accountId = smtpSendData.connectInfo.accountObjectID,
            let cdAccount = context.object(with: accountId) as? CdAccount else {
                handleError(BackgroundError.CoreDataError.couldNotFindAccount(info: nil))
                return
        }

        lastSentMessageObjectID = nil
        if let (msg, protected, cdMessageObjID) = EncryptAndSendOperation.retrieveNextMessage(
            context: context, cdAccount: cdAccount) {
            lastSentMessageObjectID = cdMessageObjID
            let uuidBeforeEngine = msg["id"]
            let session = PEPSession()
            do {
                let (_, encryptedMessageToSend) = try session.encrypt(
                    pEpMessageDict: msg, encryptionFormat: protected ? PEP_enc_PEP : PEP_enc_none)
                guard
                    var encrypted = encryptedMessageToSend?.mutableCopy()as? PEPMessageDict else {
                    Log.shared.errorAndCrash(component: #function,
                                             errorString: "Could not encrypt but did not throw.")
                     handleError(BackgroundError.PepError.encryptionError(info:
                        "Could not encrypt but did not throw."))
                    return
                }
                encrypted["id"] = uuidBeforeEngine
                setOriginalRatingHeader(toMessageWithObjId: cdMessageObjID, inContext: context)
                send(pEpMessageDict: encrypted)
            } catch let err as NSError {
                handleError(err)
            }
        } else {
            markAsFinished()
        }
    }

    private func setOriginalRatingHeader(toMessageWithObjId objId: NSManagedObjectID,
                                         inContext moc: NSManagedObjectContext) {
        guard
            let unencryptedCdMessage = privateMOC.object(with: objId) as? CdMessage,
            let unencryptedMessage = unencryptedCdMessage.message() else {
                Log.shared.errorAndCrash(component: #function, errorString: "No Message")
                handleError(BackgroundError.GeneralError.illegalState(info: "No Message"))
                return
        }

        let originalRating = unencryptedMessage.outgoingMessageRating()
        unencryptedMessage.setOriginalRatingHeader(rating: originalRating)
        unencryptedMessage.save()
    }
}

extension EncryptAndSendOperation: SmtpSendDelegate {
    public func badResponse(_ smtp: SmtpSend, response: String?) {
        let error = BackgroundError.SmtpError.badResponse(info: comp)
        handleError(error, message: "badResponse")
    }

    public func messageSent(_ smtp: SmtpSend, theNotification: Notification?) {
        handleMessageSent()
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

extension Dictionary where Key == String {
    public mutating func removeOriginalRatingHeader() {
        let headersToIgnore = Set(["X-EncStatus".lowercased()])
        let newHeaders = NSMutableArray()
        if let theHeaders = self[kPepOptFields] as? [NSArray] {
            for aHeader in theHeaders {
                if aHeader.count == 2, let headerName = aHeader[0] as? String {
                    if !headersToIgnore.contains(headerName.lowercased()) {
                        newHeaders.add(aHeader)
                    }
                }
            }
            if theHeaders.count != newHeaders.count {
                if let newValue = newHeaders as? Value {
                    self[kPepOptFields] = newValue
                } else {
                    Log.shared.warn(component: #function, content: "can't cast to `Value`")
                }
            }
        }
    }
}
