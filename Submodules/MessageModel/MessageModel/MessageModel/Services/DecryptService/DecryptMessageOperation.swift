//
//  DecryptMessageOperation.swift
//  MessageModel
//
//  Created by Andreas Buff on 23.09.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import CoreData

import pEpIOSToolbox
import PEPObjCAdapterFramework

class DecryptMessageOperation: BaseOperation {
    private let moc: NSManagedObjectContext
    private let cdMessageToDecryptObjectId: NSManagedObjectID
    private var processedCdMessaage: CdMessage?

    init(parentName: String = #file + " - " + #function,
         cdMessageToDecryptObjectId: NSManagedObjectID,
         errorContainer: ErrorContainerProtocol = ErrorPropagator()) {
        self.cdMessageToDecryptObjectId = cdMessageToDecryptObjectId
        moc = Stack.shared.newPrivateConcurrentContext
        super.init(parentName: parentName, errorContainer: errorContainer)
    }

    override func main() {
        if isCancelled {
            return
        }
        moc.performAndWait { [weak self] in
            guard let me = self else {
                Log.shared.lostMySelf()
                return
            }
            me.decryptMessage()
        }
    }
}

// MARK: - Private

extension DecryptMessageOperation {

    private func decryptMessage() {
        guard let msg = moc.object(with: cdMessageToDecryptObjectId) as? CdMessage else {
            Log.shared.errorAndCrash("No message")
            return
        }
        processedCdMessaage = msg
        guard let cdMessageToDecrypt = processedCdMessaage else {
            Log.shared.errorAndCrash("No message")
            return
        }

        let flags = cdMessageToDecrypt.isOnTrustedServer ? PEPDecryptFlags.none : .untrustedServer

        let inOutMessage = cdMessageToDecrypt.pEpMessage()
        var inOutFlags = flags
        var fprsOfExtraKeys = CdExtraKey.fprsOfAllExtraKeys(in: moc) as NSArray?
        var rating = PEPRating.undefined
        do {
            let pEpDecryptedMessage = try PEPSession().decryptMessage(inOutMessage,
                                                                      flags: &inOutFlags,
                                                                      rating: &rating,
                                                                      extraKeys: &fprsOfExtraKeys,
                                                                      status: nil)
            let ratingBeforeMessage = cdMessageToDecrypt.pEpRating
            handleDecryptionSuccess(cdMessage: cdMessageToDecrypt,
                                    pEpDecryptedMessage: pEpDecryptedMessage,
                                    inOutMessage: inOutMessage,
                                    decryptFlags: inOutFlags,
                                    ratingBeforeEngine: ratingBeforeMessage,
                                    rating: rating,
                                    keys: (fprsOfExtraKeys as? [String]) ?? [])
        } catch let error as NSError {
            if error.domain == PEPObjCAdapterEngineStatusErrorDomain {
                switch error.code {
                case Int(PEPStatus.passphraseRequired.rawValue):
                    //BUFF: keep unhandled and see how it works with the adapters new delegate approach
                    break
//                    addError(BackgroundError.PepError.passphraseRequired(info:"Passphrase required decrypting message: \(cdMessageToDecrypt)"))
//                    return // return to keep msg marked for needsDecrypt
                case Int(PEPStatus.wrongPassphrase.rawValue):
                    //BUFF: keep unhandled and see how it works with the adapters new delegate approach
                    break
//                    addError(BackgroundError.PepError.wrongPassphrase(info:"Passphrase wrong decrypting message: \(cdMessageToDecrypt)"))
//                    return // return to keep msg marked for needsDecrypt
                default:
                    Log.shared.errorAndCrash("Error decrypting: %@", "\(error)")
                    addError(BackgroundError.GeneralError.illegalState(info:
                        "##\nError: \(error)\ndecrypting message: \(cdMessageToDecrypt)\n##"))
                }
            } else if error.domain == PEPObjCAdapterErrorDomain {
                Log.shared.errorAndCrash("Unexpected ")
                addError(BackgroundError.GeneralError.illegalState(info:
                    "We do not exept this erro domain to show up here: \(error)"))
            } else {
                Log.shared.errorAndCrash("Unhandled error domain: %@", "\(error.domain)")
                addError(BackgroundError.GeneralError.illegalState(info:
                    "Unhandled error domain: \(error.domain)"))
            }
        }

        cdMessageToDecrypt.needsDecrypt = false
        moc.saveAndLogErrors()
    }

    private func handleDecryptionSuccess(cdMessage: CdMessage,
                                         pEpDecryptedMessage: PEPMessage?,
                                         inOutMessage: PEPMessage,
                                         decryptFlags: PEPDecryptFlags?,
                                         ratingBeforeEngine: Int16,
                                         rating: PEPRating,
                                         keys: [String]) {
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
        } else {
            if rating.rawValue != ratingBeforeEngine {
                cdMessage.update(rating: rating)
            }
        }
    }

    /// Updates message bodies (after decryption), then calls `updateMessage`.
    private func updateWholeMessage(pEpDecryptedMessage: PEPMessage?,
                                    rating: PEPRating,
                                    cdMessage: CdMessage,
                                    keys: [String]) {
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
    ///   - pEpMessage: decrypted message
    ///   - rating: rating to set
    private func updateMessage(cdMessage: CdMessage,
                               keys: [String],
                               pEpMessage: PEPMessage,
                               rating: PEPRating) {
        cdMessage.update(pEpMessage: pEpMessage,
                         rating: rating,
                         context: moc)
        cdMessage.updateKeyList(keys: keys, context: moc)
    }
}

// MARK: - Fake Message

extension DecryptMessageOperation {

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
                                                                context: moc)
        return updatedMessage
    }

    private func setFlags(_ flags: CdImapFlags?, toLocalFlagsOf cdMessage: CdMessage) {
        guard flags != nil else {
            // That's OK.
            // No fake message (und thus no flags) exists for the currently decrypted msg.
            return
        }
        cdMessage.imapFields().localFlags = flags
    }
}

// MARK: - Re-Upload - Trusted Server & Extry Keys

extension DecryptMessageOperation {

    private func handleReUpload(cdMessage: CdMessage,
                                inOutMessage: PEPMessage,
                                rating: PEPRating,
                                decryptFlags: PEPDecryptFlags?) {

        if cdMessage.wasAlreadyUnencrypted || // If the message was not encrypted, there is no reason to re-upload it.
            cdMessage.isAutoConsumable { // Message is an auto-consume message -> no re-upload!
            return
        }

        let flagNeedsReupload = decryptFlags?.needsReupload ?? false

        if cdMessage.isOnTrustedServer {
            // Reupload plaintext message for trusted server
            handleReUploadForTrustedServer(decryptedMessage: cdMessage, originalRating: rating)
        } else if flagNeedsReupload {
            // The Engine gave us src_modified to signal us the message needs re-upload. (has been
            // reencrypted with extra keys, Unprotected subject or whatever other reason)
            handleReUploadForReEncrypted(decryptedMessage: cdMessage,
                                         reEncryptedMessage: inOutMessage,
                                         decryptFlags: decryptFlags,
                                         originalRating: rating)
        } else {
            // The message was encrypted but has no need for reupload
        }
    }

    private func handleReUploadForTrustedServer(decryptedMessage: CdMessage,
                                                originalRating: PEPRating) {
        // Create a copy of the decrypted message for append
        let messageCopyForReupload = decryptedMessage.cloneWithZeroUID(context: moc)
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
                                                  context: moc)
        cdReEncryptedMessage.parent = decryptedMessage.parent
        if let flags = decryptFlags {
            cdReEncryptedMessage.flagsFromDecryptionRawValue = flags.rawValue
        }

        setOriginalRatingHeader(rating: originalRating, toMessage: cdReEncryptedMessage)
        // Delete the orininal, encrypted message
        decryptedMessage.imapMarkDeleted()
    }

    /// If the given message is a draft message:    sets its outgoing rating as the original rating
    /// Otherwize:                                  sets the given rating as the original rating
    private func setOriginalRatingHeader(rating: PEPRating, toMessage cdMessage: CdMessage) {
        if cdMessage.parentOrCrash.folderType == .drafts {
            let outgoingRating = cdMessage.outgoingMessageRating()
            setOriginalRatingHeaderVerbatim(rating: outgoingRating, toCdMessage: cdMessage)
        } else {
            setOriginalRatingHeaderVerbatim(rating: rating, toCdMessage: cdMessage)
        }
    }

    /// Sets the given rating as the original rating header of the given message, without any
    /// additional logic.
    private func setOriginalRatingHeaderVerbatim(rating: PEPRating, toCdMessage msg: CdMessage) {
        msg.setOriginalRatingHeader(rating: rating)
    }
}

