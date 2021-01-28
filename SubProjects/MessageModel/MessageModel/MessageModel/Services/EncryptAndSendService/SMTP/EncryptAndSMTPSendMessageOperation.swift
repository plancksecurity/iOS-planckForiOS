//
//  EncryptAndSendMessageOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 11/01/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import CoreData

import pEpIOSToolbox
import PEPObjCAdapterTypes_iOS
import PEPObjCAdapter_iOS

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

    override func main() {
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

    private func sendMessage() {
        privateMOC.perform { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            me.cdMessage = me.privateMOC.object(with: me.cdMessageToSendObjectId) as? CdMessage
            guard let cdMessage = me.cdMessage else {
                Log.shared.errorAndCrash("No msg to send")
                let error = BackgroundError.CoreDataError.couldNotFindMessage(info: "No message for ObjectId: \(me.cdMessageToSendObjectId)")
                me.handle(error: error)
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
                let extraKeys = CdExtraKey.fprsOfAllExtraKeys(in: me.privateMOC)
                PEPUtils.encrypt(pEpMessage: pEpMsg,
                                 encryptionFormat: cdMessage.pEpProtected ? .PEP : .none,
                                 extraKeys: extraKeys, errorCallback: { (error) in
                                    let error = error as NSError
                                    if error.domain == PEPObjCAdapterEngineStatusErrorDomain {
                                        if error.isPassphraseError {
                                            // The adapter is responsible to ask for passphrase. We are not.
                                            Log.shared.error("Passphrase error trying to encrypt a message")
                                            me.waitForBackgroundTasksAndFinish()
                                            return
                                        }
                                        Log.shared.errorAndCrash("Error decrypting: %@", "\(error)")
                                        me.handle(error: BackgroundError.GeneralError.illegalState(info:
                                            "##\nError: \(error)\nencrypting message: \(cdMessage)\n##"))
                                    } else if error.domain == PEPObjCAdapterErrorDomain {
                                        Log.shared.errorAndCrash("Unexpected ")
                                        me.handle(error: BackgroundError.GeneralError.illegalState(info:
                                            "We do not exept this error domain to show up here: \(error)"))
                                    } else {
                                        Log.shared.errorAndCrash("Unhandled error domain: %@", "\(error.domain)")
                                        me.handle(error: BackgroundError.GeneralError.illegalState(info:
                                            "Unhandled error domain: \(error.domain)"))
                                    }
                }) { (_, encryptedMessageToSend) in
                    me.backgroundQueue.addOperation {
                        me.privateMOC.perform {
                            me.setOriginalRatingHeader(unencryptedCdMessage: cdMessage)
                            me.send(pEpMessage: encryptedMessageToSend)
                        }
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

    private func moveLastMessageToSentFolder() {
        privateMOC.performAndWait { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            guard let cdMessage = me.cdMessage else {
                let error = BackgroundError.CoreDataError.couldNotFindMessage(info: "No message")
                me.handle(error: error)
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
            let rating = blockingGetOutgoingMessageRating(for: cdMessage)

            cdMessage.parent = sentFolder
            cdMessage.imap?.localFlags?.flagSeen = true
            cdMessage.pEpRating = Int16(rating.rawValue)

            cdMessage.createFakeMessage(context: me.privateMOC)

            me.privateMOC.saveAndLogErrors()

            Log.shared.info("Sent message with messageID %@",
                            String(describing: cdMessage.messageID))
        }
    }

    private func setOriginalRatingHeader(unencryptedCdMessage: CdMessage) {
        let originalRating = blockingGetOutgoingMessageRating(for: unencryptedCdMessage)
        unencryptedCdMessage.setOriginalRatingHeader(rating: originalRating)
        privateMOC.saveAndLogErrors()
    }

    /// THIS BLOCKS. Handle with care.
    private func blockingGetOutgoingMessageRating(for cdMessage: CdMessage) -> PEPRating {
        let group = DispatchGroup()
        group.enter()
        var outgoingRating: PEPRating? = nil
        cdMessage.outgoingMessageRating { (rating) in
            outgoingRating = rating
            group.leave()
        }
        group.wait()
        guard let rating: PEPRating = outgoingRating else {
            Log.shared.errorAndCrash("No Rating")
            return .undefined
        }
        return rating
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
    func badResponse(_ smtpConnection: SmtpConnectionProtocol, response: String?) {
        let error = BackgroundError.SmtpError.badResponse(info: comp)
        handle(error: error, message: "badResponse")
    }

    func messageSent(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {
        handleMessageSent()
    }

    func messageNotSent(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {
        let error = BackgroundError.SmtpError.messageNotSent(info: comp)
        handle(error: error, message: "messageNotSent")
    }

    func transactionInitiationCompleted(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {}

    func transactionInitiationFailed(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {
        let error = BackgroundError.SmtpError.transactionInitiationFailed(info: comp)
        handle(error: error, message: "transactionInitiationFailed")
    }

    func recipientIdentificationCompleted(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {}

    func recipientIdentificationFailed(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {
        let error = BackgroundError.SmtpError.recipientIdentificationFailed(info: comp)
        handle(error: error, message: "recipientIdentificationFailed")
    }

    func transactionResetCompleted(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {}

    func transactionResetFailed(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {
        let error = BackgroundError.SmtpError.transactionResetFailed(info: comp)
        handle(error: error, message: "transactionResetFailed")
    }

    func authenticationCompleted(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {
        addError(BackgroundError.GeneralError.illegalState(info: #function))
        waitForBackgroundTasksAndFinish()
    }

    func authenticationFailed(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {
        let error = BackgroundError.SmtpError.authenticationFailed(info: comp)
        handle(error: error, message: "authenticationFailed")
    }

    func connectionEstablished(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {}

    func connectionLost(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {
        let error = BackgroundError.SmtpError.connectionLost(info: comp)
        handle(error: error, message: "connectionLost")
    }

    func connectionTerminated(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {
        let error = BackgroundError.SmtpError.connectionTerminated(info: comp)
        handle(error: error, message: "connectionTerminated")
    }

    func connectionTimedOut(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {
        let error = BackgroundError.SmtpError.connectionTimedOut(info: comp)
        handle(error: error, message: "connectionTimedOut")
    }

    func requestCancelled(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {
        let error = BackgroundError.SmtpError.requestCancelled(info: comp)
        handle(error: error, message: "requestCancelled")
    }

    func serviceInitialized(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {}

    func serviceReconnected(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {}
}
