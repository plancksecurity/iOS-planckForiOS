//
//  DecryptMessagesOperation.swift
//  pEpForiOS
//
//  Created by hernani on 13/06/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import CoreData

import pEpIOSToolbox
import PEPObjCAdapterFramework

// Only used in Tests. Maybe refactor out.
public protocol DecryptMessagesOperationDelegateProtocol: class {
    /**
     Called whenever a message just got decrypted. Useful for tests.
     */
    func decrypted(originalCdMessage: CdMessage, decryptedMessageDict: NSDictionary?,
                   rating: PEPRating, keys: [String])
}

public class DecryptMessagesOperation: ConcurrentBaseOperation {
    public weak var delegate: DecryptMessagesOperationDelegateProtocol?// Only used in Tests. Maybe refactor out.
    private(set) var didMarkMessagesForReUpload = false

    private var cdMessagesToDecrypt = [CdMessage]()
    private var currentlyProcessedMessage: CdMessage?

    public override func main() {
        if isCancelled {
            waitForBackgroundTasksAndFinish()
            return
        }
        privateMOC.perform { [weak self] in
            guard let me = self else {
                Log.shared.lostMySelf()
                return
            }
            me.setupMessagesToDecrypt()
            guard me.cdMessagesToDecrypt.count > 0 else {
                me.waitForBackgroundTasksAndFinish()
                return
            }
            me.decryptMessages()
        }
    }
}

// MARK: - Private Worker

extension DecryptMessagesOperation {

    private func decryptMessages() {
        for cdMsgToDecrypt in cdMessagesToDecrypt {
            currentlyProcessedMessage = cdMsgToDecrypt

            let flags = cdMsgToDecrypt.isOnTrustedServer ? PEPDecryptFlags.none : .untrustedServer

            let inOutMessage = cdMsgToDecrypt.pEpMessage()
            var inOutFlags = flags
            var fprsOfExtraKeys = CdExtraKey.fprsOfAllExtraKeys(in: privateMOC) as NSArray?
            var rating = PEPRating.undefined

            do {
                let pEpDecryptedMessage = try PEPSession().decryptMessage(inOutMessage,
                                                                          flags: &inOutFlags,
                                                                          rating: &rating,
                                                                          extraKeys: &fprsOfExtraKeys,
                                                                          status: nil)
                guard let ratingBeforeMessage = currentlyProcessedMessage?.pEpRating else {
                    Log.shared.errorAndCrash("Invalid state")
                    handleError(BackgroundError.GeneralError.illegalState(info: "No Message"))
                    continue 
                }
                handleDecryptionSuccess(cdMessage: cdMsgToDecrypt,
                                        pEpDecryptedMessage: pEpDecryptedMessage,
                                        inOutMessage: inOutMessage,
                                        decryptFlags: inOutFlags,
                                        ratingBeforeEngine: ratingBeforeMessage,
                                        rating: rating,
                                        keys: (fprsOfExtraKeys as? [String]) ?? [])
            } catch {
                Log.shared.errorAndCrash("Error decrypting: %@", "\(error)")
                handleError(BackgroundError.GeneralError.illegalState(info:
                    "##\nError: \(error)\ndecrypting message: \(cdMsgToDecrypt)\n##"))
                continue
            }
        }
        waitForBackgroundTasksAndFinish()
    }

    private func setupMessagesToDecrypt() {
        guard let cdMessages = CdMessage.all(predicate: CdMessage.PredicateFactory.needToBeReProcessedByEngine(),
                                             orderedBy: [NSSortDescriptor(key: "received", ascending: true)],
                                             in: privateMOC) as? [CdMessage]
            else {
                waitForBackgroundTasksAndFinish()
                return
        }
        cdMessagesToDecrypt = cdMessages
    }

    private func handleDecryptionSuccess(cdMessage: CdMessage,
                                         pEpDecryptedMessage: PEPMessage?,
                                         inOutMessage: PEPMessage,
                                         decryptFlags: PEPDecryptFlags?,
                                         ratingBeforeEngine: Int16,
                                         rating: PEPRating,
                                         keys: [String]) {

        // Only used in Tests. Maybe refactor out.
        delegate?.decrypted(originalCdMessage: cdMessage,
                            decryptedMessageDict: pEpDecryptedMessage?.dictionary() as NSDictionary?,
                            rating: rating,
                            keys: keys)

        if rating.shouldUpdateMessageContent() {
            updateWholeMessage(pEpDecryptedMessage: pEpDecryptedMessage,
                               rating: rating,
                               cdMessage: cdMessage,
                               keys: keys)
            let updatedMessage = updatePossibleFakeMessage(forFetchedMessage: cdMessage,
                                                           pEpDecryptedMessage: pEpDecryptedMessage)
            handleReUpload(cdMessage: updatedMessage,
                           inOutMessage: inOutMessage,
                           rating: rating,
                           decryptFlags: decryptFlags)
            privateMOC.saveAndLogErrors()
        } else {
            if rating.rawValue != ratingBeforeEngine {
                cdMessage.update(rating: rating)
                privateMOC.saveAndLogErrors()
            }
        }
    }

    /// Updates message bodies (after decryption), then calls `updateMessage`.
    private func updateWholeMessage(pEpDecryptedMessage: PEPMessage?,
                                    rating: PEPRating,
                                    cdMessage: CdMessage,
                                    keys: [String]) {
        cdMessage.underAttack = rating.isUnderAttack()
        guard let decrypted = pEpDecryptedMessage else {
            Log.shared.errorAndCrash(
                "Should update message with rating %d, but nil message", rating.rawValue)
            return
        }
        updateMessage(cdMessage: cdMessage,
                      keys: keys,
                      pEpMessage: decrypted,
                      rating: rating)
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
                               pEpMessage: PEPMessage,
                               rating: PEPRating) {
        cdMessage.update(pEpMessage: pEpMessage,
                         rating: rating,
                         context: privateMOC)
        cdMessage.updateKeyList(keys: keys, context: privateMOC)
    }
}

// MARK: - Fake Message

extension DecryptMessagesOperation {

    /// Finds and updates the local fake message (if exists) for a given message fetched from
    /// server.
    ///
    /// - Parameters:
    ///   - cdMessage:  the message to update, fetched from server. MUST NOT be used any more after
    ///                 passing it to this method
    ///   - pEpDecryptedMessage: decrypted message.
    ///                             We need it as the uuid differs in Mesasge >=2.0
    ///                             (inner message uuid vs. outer message)
    ///
    /// -note:  cdMesasge MUST NOT be used any more after passing it to this method. It might have
    ///         been deleted while updating the fake message.
    /// - Returns: updated fake message if existed, forFetchedMessage otherwize.
    private func updatePossibleFakeMessage(forFetchedMessage cdMessage: CdMessage,
                                           pEpDecryptedMessage: PEPMessage?) -> CdMessage {
        guard let uuid = pEpDecryptedMessage?.messageID else {
            Log.shared.errorAndCrash("No uuid")
            return cdMessage
        }

        let updatedMessage = CdMessage.findAndUpdateFakeMessage(withUuid: uuid,
                                                                realMessage: cdMessage,
                                                                context: privateMOC)
        return updatedMessage
    }
}

// MARK: - Re-Upload - Trusted Server & Extry Keys

extension DecryptMessagesOperation {

    private func handleReUpload(cdMessage: CdMessage,
                                inOutMessage: PEPMessage,
                                rating: PEPRating,
                                decryptFlags: PEPDecryptFlags?) {
        didMarkMessagesForReUpload = handleReUploadIfRequired(cdMessage: cdMessage,
                                                              inOutMessage: inOutMessage,
                                                              rating: rating,
                                                              decryptFlags: decryptFlags)
    }

    private func handleReUploadIfRequired(cdMessage: CdMessage,
                                          inOutMessage: PEPMessage,
                                          rating: PEPRating,
                                          decryptFlags: PEPDecryptFlags?) -> Bool {

        if cdMessage.wasAlreadyUnencrypted || // If the message was not encrypted, there is no reason to re-upload it.
            cdMessage.isAutoConsumable { // Message is an auto-consume message -> no re-upload!
            return false
        }

        let flagNeedsReupload = decryptFlags?.needsReupload ?? false

        if cdMessage.isOnTrustedServer { // Reupload plaintext message for trusted server
            handleReUploadForTrustedServer(decryptedMessage: cdMessage, originalRating: rating)
            return true
        } else if flagNeedsReupload { // Reupload message which has been reencrypted with extra keys
            handleReUploadForReEncrypted(decryptedMessage: cdMessage,
                                         reEncryptedMessage: inOutMessage,
                                         decryptFlags: decryptFlags,
                                         originalRating: rating)
            return true
        } else {
            // The message was encrypted but has no need for reupload
            return false
        }
    }

    private func handleReUploadForTrustedServer(decryptedMessage: CdMessage,
                                                originalRating: PEPRating) {
        // Create a copy of the decrypted message for append
        let messageCopyForReupload = decryptedMessage.cloneWithZeroUID(context: privateMOC)
        setOriginalRatingHeader(rating: originalRating, toMessage: messageCopyForReupload)
        // Delete the orininal, encrypted message
        decryptedMessage.imapMarkDeleted()
    }

    private func handleReUploadForReEncrypted(decryptedMessage: CdMessage,
                                              reEncryptedMessage: PEPMessage,
                                              decryptFlags: PEPDecryptFlags?,
                                              originalRating: PEPRating) {
        // Create the reEncryptedMessage for append
        let cdReEncryptedMessage = CdMessage.from(pEpMessage: reEncryptedMessage,
                                                   inContext: privateMOC)
        cdReEncryptedMessage.parent = decryptedMessage.parent
        if let flags = decryptFlags {
            cdReEncryptedMessage.flagsFromDecryptionRawValue = flags.rawValue
        }

        setOriginalRatingHeader(rating: originalRating, toMessage: cdReEncryptedMessage)
        // Delete the orininal, encrypted message
        decryptedMessage.imapMarkDeleted()
    }

    /**
     If the given message is a draft message, sets its outgoing rating as the
     original rating, if not, use the given rating.
     */
    private func setOriginalRatingHeader(rating: PEPRating, toMessage cdMessage: CdMessage) {
        if cdMessage.parentOrCrash.folderType == .drafts {
            let outgoingRating = cdMessage.outgoingMessageRating()
            setOriginalRatingHeaderVerbatim(rating: outgoingRating, toCdMessage: cdMessage)
        } else {
            setOriginalRatingHeaderVerbatim(rating: rating, toCdMessage: cdMessage)
        }
    }

    /**
     Sets the given rating as the original rating header of the given message,
     without any additional logic.
     */
    private func setOriginalRatingHeaderVerbatim(rating: PEPRating, toCdMessage msg: CdMessage) {
        msg.setOriginalRatingHeader(rating: rating)
    }
}
