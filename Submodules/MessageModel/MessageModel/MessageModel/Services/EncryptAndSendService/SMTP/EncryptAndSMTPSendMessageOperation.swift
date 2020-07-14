//
//  EncryptAndSendMessageOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 11/01/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import CoreData

import pEpIOSToolbox
import PEPObjCAdapterFramework

/// Encrypts and SMTPs a given messages.
class EncryptAndSMTPSendMessageOperation: ConcurrentBaseOperation {
    private var smtpConnection: SmtpConnectionProtocol
    private var cdMessage: CdMessage? = nil
    private let cdMessageToSendObjectId: NSManagedObjectID

    /** The object ID of the last sent message, so we can move it on success */
    private var lastSentMessageObjectID: NSManagedObjectID?

    init(parentName: String = #file + #function,
         cdMessageToSendObjectId: NSManagedObjectID,
         smtpConnection: SmtpConnectionProtocol,
         errorContainer: ErrorContainerProtocol = ErrorPropagator()) {
        self.cdMessageToSendObjectId = cdMessageToSendObjectId
        self.smtpConnection = smtpConnection
        super.init(parentName: parentName, errorContainer: errorContainer)
    }

    override public func main() {
        if isCancelled {
            waitForBackgroundTasksAndFinish()
            return
        }
        smtpConnection.delegate = self
        sendMessage()
    }
}

// MARK: - Private

extension EncryptAndSMTPSendMessageOperation {

    private func sendMessage() {//!!!: IOS-2325_!
        privateMOC.perform { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            me.cdMessage = me.privateMOC.object(with: me.cdMessageToSendObjectId) as? CdMessage
            guard let cdMessage = me.cdMessage else {
                Log.shared.errorAndCrash("No msg to send")
                let error = BackgroundError.CoreDataError.couldNotFindMessage(info: "No message for ObjectId: \(me.cdMessageToSendObjectId)")
                me.handleError(error)
                return
            }
            cdMessage.sent = Date()
            let pEpMsg = cdMessage.pEpMessage()

            if cdMessage.isAutoConsumable {
                // The Engine asked us to send this message (by calling the send callback).
                // Thus the Engine has crafted this message. Do not pass to the Engine again.
                // Simply send out.
                me.send(pEpMessage: pEpMsg)
            } else {
                do {
                    let exrtaKeys = CdExtraKey.fprsOfAllExtraKeys(in: me.privateMOC)
                    let encryptedMessageToSend =
                        try PEPUtils.encrypt(pEpMessage: pEpMsg,//!!!: IOS-2325_!
                                             encryptionFormat: cdMessage.pEpProtected ? .PEP : .none,
                                             extraKeys: exrtaKeys)
                    me.setOriginalRatingHeader(unencryptedCdMessage: cdMessage)
                    me.send(pEpMessage: encryptedMessageToSend)
                } catch let error as NSError {
                    if error.domain == PEPObjCAdapterEngineStatusErrorDomain {
                        switch error.code {
                        case Int(PEPStatus.passphraseRequired.rawValue):
                            //BUFF: keep unhandled and see how it works with the adapters new delegate approach
                            break
//                            me.handleError(BackgroundError.PepError.passphraseRequired(info:"Passphrase required encrypting message: \(cdMessage)"))
                        case Int(PEPStatus.wrongPassphrase.rawValue):
                            //BUFF: keep unhandled and see how it works with the adapters new delegate approach
                            break
//                            me.handleError(BackgroundError.PepError.wrongPassphrase(info:"Passphrase wrong encrypting message: \(cdMessage)"))
                        default:
                            Log.shared.errorAndCrash("Error decrypting: %@", "\(error)")
                            me.handleError(BackgroundError.GeneralError.illegalState(info:
                                "##\nError: \(error)\nencrypting message: \(cdMessage)\n##"))
                        }
                    } else if error.domain == PEPObjCAdapterErrorDomain {
                        Log.shared.errorAndCrash("Unexpected ")
                        me.handleError(BackgroundError.GeneralError.illegalState(info:
                            "We do not exept this error domain to show up here: \(error)"))
                    } else {
                        Log.shared.errorAndCrash("Unhandled error domain: %@", "\(error.domain)")
                        me.handleError(BackgroundError.GeneralError.illegalState(info:
                            "Unhandled error domain: \(error.domain)"))
                    }
                }
            }
        }
    }

    private func send(pEpMessage: PEPMessage) {
        pEpMessage.removeOriginalRatingHeader()

        let pantMail = PEPUtils.pantomime(pEpMessage: pEpMessage)
        smtpConnection.setRecipients(nil)
        smtpConnection.setMessageData(nil)
        smtpConnection.setMessage(pantMail)
        smtpConnection.sendMessage()
    }

    private func moveLastMessageToSentFolder() {//!!!: IOS-2325_!
        privateMOC.performAndWait { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            guard let cdMessage = me.cdMessage else {
                let error = BackgroundError.CoreDataError.couldNotFindMessage(info: "No message")
                me.handleError(error)
                return
            }
            guard
                let cdAccount = cdMessage.parent?.account,
                let sentFolder = CdFolder.by(folderType: .sent,
                                             account: cdAccount,
                                             context: me.privateMOC)
                else {
                    Log.shared.errorAndCrash("Problem moving last message")
                    me.waitForBackgroundTasksAndFinish()
                    return
            }

            guard !cdMessage.isAutoConsumable else {
                // We MUST NOT append messages the Engine asked us to send for a certain pEP
                // protocol (KeySync, KeyReset ...) to the Sent folder.
                // Simply delete it.
                me.privateMOC.delete(cdMessage)
                me.privateMOC.saveAndLogErrors()
                return
            }

            let rating = cdMessage.outgoingMessageRating().rawValue//!!!: IOS-2325_!

            cdMessage.parent = sentFolder
            cdMessage.imap?.localFlags?.flagSeen = true
            cdMessage.pEpRating = Int16(rating)

            cdMessage.createFakeMessage(context: me.privateMOC)

            me.privateMOC.saveAndLogErrors()

            Log.shared.info("Sent message with messageID %@",
                            String(describing: cdMessage.messageID))
        }
    }

    private func setOriginalRatingHeader(unencryptedCdMessage: CdMessage) {//!!!: IOS-2325_!
        let originalRating = unencryptedCdMessage.outgoingMessageRating()//!!!: IOS-2325_!
        unencryptedCdMessage.setOriginalRatingHeader(rating: originalRating)
        privateMOC.saveAndLogErrors()
    }
}

// MARK: - Callback Handler

extension EncryptAndSMTPSendMessageOperation {

    fileprivate func handleMessageSent() {
        backgroundQueue.addOperation { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            me.moveLastMessageToSentFolder()
            me.waitForBackgroundTasksAndFinish()
        }
    }
}

// MARK: - SmtpSendDelegate

extension EncryptAndSMTPSendMessageOperation: SmtpConnectionDelegate {
    public func badResponse(_ smtpConnection: SmtpConnectionProtocol, response: String?) {
        let error = BackgroundError.SmtpError.badResponse(info: comp)
        handleError(error, message: "badResponse")
    }

    public func messageSent(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {
        handleMessageSent()
    }

    public func messageNotSent(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {
        let error = BackgroundError.SmtpError.messageNotSent(info: comp)
        handleError(error, message: "messageNotSent")
    }

    public func transactionInitiationCompleted(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {}

    public func transactionInitiationFailed(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {
        let error = BackgroundError.SmtpError.transactionInitiationFailed(info: comp)
        handleError(error, message: "transactionInitiationFailed")
    }

    public func recipientIdentificationCompleted(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {}

    public func recipientIdentificationFailed(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {
        let error = BackgroundError.SmtpError.recipientIdentificationFailed(info: comp)
        handleError(error, message: "recipientIdentificationFailed")
    }

    public func transactionResetCompleted(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {}

    public func transactionResetFailed(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {
        let error = BackgroundError.SmtpError.transactionResetFailed(info: comp)
        handleError(error, message: "transactionResetFailed")
    }

    public func authenticationCompleted(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {
        addError(BackgroundError.GeneralError.illegalState(info: #function))
        waitForBackgroundTasksAndFinish()
    }

    public func authenticationFailed(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {
        let error = BackgroundError.SmtpError.authenticationFailed(info: comp)
        handleError(error, message: "authenticationFailed")
    }

    public func connectionEstablished(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {}

    public func connectionLost(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {
        let error = BackgroundError.SmtpError.connectionLost(info: comp)
        handleError(error, message: "connectionLost")
    }

    public func connectionTerminated(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {
        let error = BackgroundError.SmtpError.connectionTerminated(info: comp)
        handleError(error, message: "connectionTerminated")
    }

    public func connectionTimedOut(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {
        let error = BackgroundError.SmtpError.connectionTimedOut(info: comp)
        handleError(error, message: "connectionTimedOut")
    }

    public func requestCancelled(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {
        let error = BackgroundError.SmtpError.requestCancelled(info: comp)
        handleError(error, message: "requestCancelled")
    }

    public func serviceInitialized(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {}

    public func serviceReconnected(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {}
}
