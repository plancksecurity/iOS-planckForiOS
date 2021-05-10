//
//  EncryptAndSendMessageOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 11/01/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import CoreData

import PEPObjCAdapterTypes_iOS
import PEPObjCAdapter_iOS

#if EXT_SHARE
import pEpIOSToolboxForExtensions
#else
import pEpIOSToolbox
#endif

/// Encrypts and SMTPs a given messages.
class EncryptAndSMTPSendMessageOperation: ConcurrentBaseOperation {
    private var smtpConnection: SmtpConnectionProtocol
    private var cdMessage: CdMessage? = nil
    private let cdMessageToSendObjectId: NSManagedObjectID
    weak private var encryptionErrorDelegate: EncryptionErrorDelegate?

    // MARK: - API

    init(parentName: String = #file + #function,
         cdMessageToSendObjectId: NSManagedObjectID,
         smtpConnection: SmtpConnectionProtocol,
         errorContainer: ErrorContainerProtocol = ErrorPropagator(),
         encryptionErrorDelegate: EncryptionErrorDelegate? = nil) {
        self.cdMessageToSendObjectId = cdMessageToSendObjectId
        self.smtpConnection = smtpConnection
        self.encryptionErrorDelegate = encryptionErrorDelegate
        super.init(parentName: parentName, errorContainer: errorContainer)
    }

    override func main() {
        if isCancelled {
            waitForBackgroundTasksAndFinish()
            return
        }
        smtpConnection.delegate = self
        privateMOC.perform { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            me.perform()
        }
    }
}

// MARK: - Private

extension EncryptAndSMTPSendMessageOperation {

    private func perform() {
        cdMessage = privateMOC.object(with: cdMessageToSendObjectId) as? CdMessage
        guard let cdMessage = cdMessage else {
            Log.shared.errorAndCrash("No msg to send")
            let error = BackgroundError.CoreDataError.couldNotFindMessage(info: "No message for ObjectId: \(cdMessageToSendObjectId)")
            handle(error: error)
            return
        }
        cdMessage.pEpRating = Int16(PEPRating.undefined.rawValue)
        cdMessage.sent = Date()
        let pEpMsg = cdMessage.pEpMessage()

        guard !cdMessage.isAutoConsumable else {
            // The Engine asked us to send this message (by calling the send callback).
            // Thus the Engine has crafted this message. Do not pass to the Engine again.
            // Simply send out.
            send(pEpMessage: pEpMsg)
            return
        }
        let extraKeys = CdExtraKey.fprsOfAllExtraKeys(in: privateMOC)
        PEPUtils.encrypt(pEpMessage: pEpMsg,
                         encryptionFormat: cdMessage.pEpProtected ? .PEP : .none,
                         extraKeys: extraKeys,
                         errorCallback:
                            { [weak self] (error) in
                                // ERROR
                                guard let me = self else {
                                    Log.shared.errorAndCrash("Lost myself")
                                    return
                                }
                                me.privateMOC.perform {
                                    me.handleEncryptionError(error: error as NSError)
                                }
                            })
        { [weak self] (_, encryptedMessageToSend) in
            // SUCCESS
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            me.backgroundQueue.addOperation {
                me.privateMOC.perform {
                    me.setOriginalRatingHeader(unencryptedCdMessage: cdMessage)
                    me.send(pEpMessage: encryptedMessageToSend)
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

            cdMessage.parent = sentFolder
            cdMessage.imap?.localFlags?.flagSeen = true
            if cdMessage.pEpRating == PEPRating.undefined.rawValue {
                // We MUST NOT set outgoing rating if the rating has already been defined as
                // unencrypted by handling encryption errors!
                // Backgound: this may cause showing yellow or green for a message that could not
                // be encrypted!
                // See IOS-2823
                cdMessage.pEpRating = Int16(blockingGetOutgoingMessageRating(for: cdMessage).rawValue)
            }

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

// MARK: - Encryption Error Handling

extension EncryptAndSMTPSendMessageOperation {

    private func handleEncryptionError(error: NSError) {
        if error.domain == PEPObjCAdapterEngineStatusErrorDomain ||
            error.domain == PEPObjCAdapterErrorDomain
        {
            if error.isPassphraseError {
                // The adapter is responsible to ask for passphrase. We are not.
                Log.shared.error("Passphrase error trying to encrypt a message")
                waitForBackgroundTasksAndFinish()
                return
            }
            Log.shared.error("Error encrypting: %@", "\(error)")
            makeSureMessageWithColorIsNotSentOutUnencryptedWithoutNotice()
        } else {
            Log.shared.errorAndCrash("Unhandled error domain: %@", "\(error.domain)")
            handle(error: BackgroundError.GeneralError.illegalState(info: "Unhandled error domain: \(error.domain)"))
        }
    }

    private func makeSureMessageWithColorIsNotSentOutUnencryptedWithoutNotice() {
        guard let delegate = encryptionErrorDelegate else {
            Log.shared.info("No delegate set")
            moveToDrafts()
            return
        }
        guard let msg = cdMessage else {
            Log.shared.errorAndCrash("No message!")
            moveToDrafts()
            return
        }
        var rating: PEPRating? = nil
        let group = DispatchGroup()
        group.enter()
        msg.outgoingMessageRating { (rtg) in
            rating = rtg
            group.leave()
        }
        group.wait()
        guard let outgoingMsgRating = rating else {
            Log.shared.errorAndCrash("No rating!")
            moveToDrafts()
            return
        }
        let outgoingColor = PEPSession().color(from: outgoingMsgRating)
        guard outgoingColor == .green || outgoingColor == .yellow else {
            // Is unprotected mail. Send out unencrypted without bothering.
            sendUnencrypted()
            return
        }
        // Message was yellow or green but could not be encrypted.
        // Ask the responsible person what to do now and act according to the returend decision.
        delegate.handleCouldNotEncrypt() { [weak self] sendUnencrypted in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            me.privateMOC.perform {
                if sendUnencrypted {
                    //                        me.cdMessage?.pEpProtected = false
                    me.sendUnencrypted()
                } else {
                    me.moveToDrafts()
                }
            }
        }
    }

    /// Move the message to drafts folder. Probably because we had an issue encrypting.
    private func moveToDrafts() {
        privateMOC.performAndWait { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }

            defer { me.waitForBackgroundTasksAndFinish() }

            guard let cdMessageToMove = me.cdMessage,
                  let cdAccount = cdMessageToMove.parent?.account
            else {
                Log.shared.errorAndCrash("Missing required data!")
                return
            }
            let draftsFolder = CdFolder.by(folderType: .drafts,
                                           account: cdAccount,
                                           context: me.privateMOC)
            cdMessageToMove.parent = draftsFolder
            me.privateMOC.saveAndLogErrors()
        }
    }

    private func sendUnencrypted() {
        backgroundQueue.addOperation { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            me.privateMOC.perform {
                me.cdMessage?.pEpRating = Int16(PEPRating.unencrypted.rawValue)
                guard let unencryptedMessage = me.cdMessage?.pEpMessage() else {
                    Log.shared.errorAndCrash("No Message")
                    return
                }
                me.send(pEpMessage: unencryptedMessage)
            }
        }
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
