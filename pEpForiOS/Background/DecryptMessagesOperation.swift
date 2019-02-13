//
//  DecryptMessagesOperation.swift
//  pEpForiOS
//
//  Created by hernani on 13/06/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import MessageModel

import CoreData

// Only used in Tests. Maybe refactor out.
public protocol DecryptMessagesOperationDelegateProtocol: class {
    /**
     Called whenever a message just got decrypted. Useful for tests.
     */
    func decrypted(originalCdMessage: CdMessage, decryptedMessageDict: NSDictionary?,
                   rating: PEP_rating, keys: [String])
}

public class DecryptMessagesOperation: ConcurrentBaseOperation {
    public weak var delegate: DecryptMessagesOperationDelegateProtocol?// Only used in Tests. Maybe refactor out.
    private(set) var didMarkMessagesForReUpload = false

    private var messagesToDecrypt = [CdMessage]()
    private var currentlyProcessedMessage: CdMessage?
    private var ratingBeforeEngine = Int16(PEP_rating_undefined.rawValue)

    private func setupMessagesToDecrypt() {
        privateMOC.performAndWait {[weak self] in
            guard let me = self else {
                Logger.backendLogger.lostMySelf()
                return
            }
            guard let cdMessages = CdMessage.all(
                predicate: CdMessage.PredicateFactory.unknownToPep(),
                orderedBy: [NSSortDescriptor(key: "received", ascending: true)],
                in: privateMOC) as? [CdMessage] else {
                    me.markAsFinished()
                    return
            }
            messagesToDecrypt = cdMessages
        }
    }

    public override func main() {
        if isCancelled {
            markAsFinished()
            return
        }
        setupMessagesToDecrypt()
        handleNextMessage()
    }

    // MARK: - Process

    private func cleanup() {
        currentlyProcessedMessage = nil
        ratingBeforeEngine = Int16(PEP_rating_undefined.rawValue)
    }

    private func handleNextMessage() {
        cleanup()

        if messagesToDecrypt.count == 0 {
            waitForBackgroundTasksToFinish()
            return
        }

        privateMOC.perform { [weak self] in
            guard let me = self else {
                Logger.backendLogger.lostMySelf()
                return
            }
            if me.isCancelled {
                me.waitForBackgroundTasksToFinish()
                return
            }
            let cdMsg = me.messagesToDecrypt.removeFirst()
            me.currentlyProcessedMessage = cdMsg
            guard let msg = cdMsg.message() else {
                Logger.backendLogger.errorAndCrash("No message")
                me.handleError(
                    BackgroundError.GeneralError.illegalState(info: "No Message for CdMessage"))
                return
            }
            me.ratingBeforeEngine = cdMsg.pEpRating
            var outgoing = false
            if let folderType = cdMsg.parent?.folderType {
                outgoing = folderType.isOutgoing()
            }
            let pepMessage = PEPUtil.pEpDict(cdMessage: cdMsg, outgoing: outgoing)
            let flags = msg.isOnTrustedServer ? PEP_decrypt_flag_none :
            PEP_decrypt_flag_untrusted_server
            let decryptOp = DecryptMessageOperation(messageToDecrypt: pepMessage,
                                                    flags: flags,
                                                    delegate: me)
            me.backgroundQueue.addOperation(decryptOp)
        }
    }

    // MARK: - Handle Result

    private func handleDecryptionSuccess(cdMessage: CdMessage,
                                         pEpDecryptedMessage: NSDictionary,
                                         ratingBeforeEngine: Int16,
                                         rating: PEP_rating,
                                         keys: NSArray?) {
        privateMOC.performAndWait {[weak self] in
            guard let me = self else {
                Logger.backendLogger.lostMySelf()
                return
            }
            let theKeys = Array(keys ?? NSArray()) as? [String] ?? []

            // Only used in Tests. Maybe refactor out.
            me.delegate?.decrypted(originalCdMessage: cdMessage,
                                     decryptedMessageDict: pEpDecryptedMessage,
                                     rating: rating,
                                     keys: theKeys)

            if rating.shouldUpdateMessageContent() {
                me.updateWholeMessage(pEpDecryptedMessage: pEpDecryptedMessage,
                                   ratingBeforeEngine: ratingBeforeEngine,
                                   rating: rating,
                                   cdMessage: cdMessage,
                                   keys: theKeys)
                findDeleteAndHandleFakeMessage(forFetchedMessage: cdMessage,
                                               pEpDecryptedMessage: pEpDecryptedMessage)
                me.handleReUploadAndNotify(cdMessage: cdMessage, rating: rating)
            } else {
                if rating.rawValue != ratingBeforeEngine {
                    cdMessage.update(rating: rating)
                    saveAndNotify(cdMessage: cdMessage  )
                }
            }
        }
    }

    /// Finds and deletes the local fake message (if exists) for a given message fetched from
    /// server. It also takes over the imap flags of the fake message. The user might have changed
    /// them (read or flagged the message) meanwhile.
    ///
    /// - Parameters:
    ///   - cdMessage: the message fetched from server
    ///   - pEpDecryptedMessage: decrypted message.
    ///                             We need it as the uuid differs in Mesasge >=2.0
    ///                             (inner message uui vs. outer message)
    private func findDeleteAndHandleFakeMessage(forFetchedMessage cdMessage: CdMessage,
                                                pEpDecryptedMessage: NSDictionary) {
        guard
            let uuid = pEpDecryptedMessage["id"] as? String,
            let parentFolder = cdMessage.parent?.folder()  else {
                Log.shared.errorAndCrash(component: #function, errorString:"Problem")
                return
        }
        let imapFlagsFakeMessage = Message.findAndDeleteFakeMessage(withUuid: uuid,
                                                                    in: parentFolder)
        setFlags(imapFlagsFakeMessage, toCdMessage: cdMessage)
    }

    /**
     Updates message bodies (after decryption), then calls `updateMessage`.
     */
    private func updateWholeMessage(pEpDecryptedMessage: NSDictionary?,
                                    ratingBeforeEngine: Int16,
                                    rating: PEP_rating,
                                    cdMessage: CdMessage,
                                    keys: [String]) {
        cdMessage.underAttack = rating.isUnderAttack()
        guard let decrypted = pEpDecryptedMessage as? PEPMessageDict else {

                Logger.backendLogger.errorAndCrash(
                    "Should update message with rating %d, but nil message",
                    rating.rawValue)
                return
        }
        updateMessage(cdMessage: cdMessage, keys: keys, pEpMessageDict: decrypted, rating: rating)
    }

    private func setFlags(_ flags: Message.ImapFlags?,
                          toCdMessage cdMessage: CdMessage) {
        guard let imapFlags = flags else {
            // That's OK.
            // No fake message (und thus no flags) exists for the currently decrypted msg.
            return
        }
        cdMessage.imap?.localFlags?.flagDraft = imapFlags.draft
        cdMessage.imap?.localFlags?.flagAnswered = imapFlags.answered
        cdMessage.imap?.localFlags?.flagDeleted = imapFlags.deleted
        cdMessage.imap?.localFlags?.flagSeen = imapFlags.seen
    }

    private func handleReUploadAndNotify(cdMessage: CdMessage, rating: PEP_rating) {
        do {
            let needsReUpload = try handleReUploadIfRequired(cdMessage: cdMessage, rating: rating)
            if needsReUpload {
                didMarkMessagesForReUpload = true
                Record.saveAndWait()
                privateMOC.saveAndLogErrors()
                // Don't notify. Delegate will be notified after the re-uploaded message is fetched.
            } else {
                saveAndNotify(cdMessage: cdMessage)
            }
        } catch {
            handleError(error)
        }
    }

    private func saveAndNotify(cdMessage: CdMessage) {
        privateMOC.saveAndLogErrors()
        notifyDelegate(messageUpdated: cdMessage)
    }

    /// Updates a message with the given data.
    ///
    /// - Parameters:
    ///   - cdMessage: message to update
    ///   - keys: keys the message has been signed with
    ///   - pEpMessageDict: decrypted message
    ///   - rating: rating to set
    private func updateMessage(cdMessage: CdMessage,
                               keys: [String],
                               pEpMessageDict: PEPMessageDict,
                               rating: PEP_rating) {
        cdMessage.update(pEpMessageDict: pEpMessageDict, rating: rating)
        cdMessage.updateKeyList(keys: keys)
    }

    private func notifyDelegate(messageUpdated cdMessage: CdMessage) {
        guard let message = cdMessage.message() else {
            Logger.backendLogger.errorAndCrash("Error converting CDMesage")
            return
        }
        MessageModelConfig.messageFolderDelegate?.didCreate(messageFolder: message)
    }

    // MARK: - Handle DecryptMessageOperationDelegate Calls

    private func decryptMessageOperationDidDecryptMessage(result:
        DecryptMessageOperation.DecryptionResult) {
        guard
            let decrypted = result.pEpDecryptedMessage,
            let currentlyProcessedMessage = currentlyProcessedMessage else {
                Logger.backendLogger.errorAndCrash("Invalid state")
                handleError(BackgroundError.GeneralError.illegalState(info:
                    "Error handling decryption result"))
                return
        }
        handleDecryptionSuccess(cdMessage: currentlyProcessedMessage,
                                pEpDecryptedMessage: decrypted,
                                ratingBeforeEngine: ratingBeforeEngine,
                                rating: result.rating,
                                keys: result.keys)
        handleNextMessage()
    }

    private func decryptMessageOperationDidFail(error: Error) {
        addError(error)
        handleNextMessage()
    }
}

// MARK: - Re-Upload - Trusted Server

extension DecryptMessagesOperation {
    private func handleReUploadIfRequired(cdMessage: CdMessage,
                                          rating: PEP_rating) throws -> Bool {
        guard let message = cdMessage.message() else {
            Logger.backendLogger.errorAndCrash("No message")
            throw BackgroundError.GeneralError.illegalState(info: "No Message")
        }
        if !message.isOnTrustedServer ||    // The only currently supported case for re-upload is trusted server.
            message.wasAlreadyUnencrypted { // If the message was not encrypted, there is no reason to re-upload it.
            return false
        }   
        let messageCopyForReupload = Message(message: message)
        setOriginalRatingHeader(rating: rating, toMessage: messageCopyForReupload)
        message.imapMarkDeleted()

        return true
    }

    private func setOriginalRatingHeader(rating: PEP_rating, toMessage cdMessage: CdMessage) {
        guard let message = cdMessage.message() else {
            Logger.backendLogger.errorAndCrash("No message")
            handleError(BackgroundError.GeneralError.illegalState(info: "No Message"))
            return
        }
        if message.parent.folderType == .drafts {
            let outgoingRating = message.outgoingMessageRating()
            setOriginalRatingHeader(rating: outgoingRating, toMessage: message)
        } else {
            setOriginalRatingHeader(rating: rating, toMessage: message)
        }
    }

    private func setOriginalRatingHeader(rating: PEP_rating, toMessage msg: Message) {
        msg.setOriginalRatingHeader(rating: rating)
        msg.save()
    }
}

// MARK: - DecryptMessageOperationDelegate

extension DecryptMessagesOperation: DecryptMessageOperationDelegate {
    func decryptMessageOperation(sender: DecryptMessageOperation,
                                 didDecryptMessageWithResult result:
        DecryptMessageOperation.DecryptionResult) {
        decryptMessageOperationDidDecryptMessage(result: result)
    }

    func decryptMessageOperation(sender: DecryptMessageOperation, failed error: Error) {
        decryptMessageOperationDidFail(error: error)
    }
}
