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

        guard !cdMessageToDecrypt.isDeleted else {
            /// Valid case, the message or the account is already deleted.
            return
        }
        var inOutFlags = cdMessageToDecrypt.isOnTrustedServer ? PEPDecryptFlags.none : .untrustedServer
        var inOutMessage = cdMessageToDecrypt.pEpMessage()
        var fprsOfExtraKeys = CdExtraKey.fprsOfAllExtraKeys(in: moc)
        var rating = PEPRating.undefined
        var pEpDecryptedMessage: PEPMessage? = nil

        // We must block here until the adapter calls back. Else we will not exist any more when it
        // does and thus can not handle its results.
        var nsError: NSError? = nil
        var isAFormerlyEncryptedReuploadedMessage = false
        let group = DispatchGroup()
        group.enter()
        PEPSession().decryptMessage(inOutMessage, flags: inOutFlags, extraKeys: fprsOfExtraKeys, errorCallback: { (error) in
            nsError = error as NSError
            group.leave()
        }) { (pEpSourceMessage, pEpDecryptedMsg, keyList, pEpRating, decryptFlags, isFormerlyEncryptedReuploadedMessage) in
            inOutMessage = pEpSourceMessage
            pEpDecryptedMessage = pEpDecryptedMsg
            fprsOfExtraKeys = keyList
            rating = pEpRating
            inOutFlags = decryptFlags
            isAFormerlyEncryptedReuploadedMessage = isFormerlyEncryptedReuploadedMessage
            group.leave()
        }
        group.wait()

        if let error = nsError {
            // An error occured
            if error.domain == PEPObjCAdapterEngineStatusErrorDomain {
                if error.isPassphraseError {
                    // The adapter is responsible to handle this case.
                    Log.shared.error("Passphrase error trying to decrypt a message")
                    return
                }
                Log.shared.errorAndCrash("Error decrypting: %@", "\(error)")
                addError(BackgroundError.GeneralError.illegalState(info:
                    "##\nError: \(error)\ndecrypting message: \(cdMessageToDecrypt)\n##"))
            } else if error.domain == PEPObjCAdapterErrorDomain {
                Log.shared.errorAndCrash("Unexpected ")
                addError(BackgroundError.GeneralError.illegalState(info:
                    "We do not expect this error domain to show up here: \(error)"))
            } else {
                Log.shared.errorAndCrash("Unhandled error domain: %@", "\(error.domain)")
                addError(BackgroundError.GeneralError.illegalState(info:
                    "Unhandled error domain: \(error.domain)"))
            }
        } else {
            let ratingBeforeMessage = cdMessageToDecrypt.pEpRating
            handleDecryptionSuccess(cdMessage: cdMessageToDecrypt,
                                    pEpDecryptedMessage: pEpDecryptedMessage,
                                    inOutMessage: inOutMessage,
                                    decryptFlags: inOutFlags,
                                    ratingBeforeEngine: ratingBeforeMessage,
                                    rating: rating,
                                    keys: fprsOfExtraKeys ?? [],
                                    isFormerlyEncryptedReuploadedMessage: isAFormerlyEncryptedReuploadedMessage)
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
                                         keys: [String],
                                         isFormerlyEncryptedReuploadedMessage: Bool) {
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
                           decryptFlags: decryptFlags,
                           isFormerlyEncryptedReuploadedMessage: isFormerlyEncryptedReuploadedMessage)
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
            //Valid case. No message can be found because the it has been deleted from the DB.
            // Probably the user deleted the belonging Account
            return cdMessage
        }

        let updatedMessage = CdMessage.findAndUpdateFakeMessage(withUuid: uuid,
                                                                realMessage: cdMessage,
                                                                context: moc)
        return updatedMessage
    }
}

// MARK: - Re-Upload - Trusted Server & Extry Keys

extension DecryptMessageOperation {

    private func handleReUpload(cdMessage: CdMessage,
                                inOutMessage: PEPMessage,
                                rating: PEPRating,
                                decryptFlags: PEPDecryptFlags?,
                                isFormerlyEncryptedReuploadedMessage: Bool) {

        if isFormerlyEncryptedReuploadedMessage || // The Eninge told us that this message is a formerly encrypted message that has been reuploaded for trusted server. Do not reupload again.
            PEPUtils.pEpRatingFromInt(Int(cdMessage.pEpRating)) == .unencrypted || // If the message was not encrypted, there is no reason to re-upload it.
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
            let group = DispatchGroup()
            group.enter()
            var outgoingRating: PEPRating? = nil
            cdMessage.outgoingMessageRating { (rating) in
                outgoingRating = rating
                group.leave()
            }
            group.wait()
            guard let rating = outgoingRating else {
                Log.shared.errorAndCrash("No Rating")
                return
            }
            setOriginalRatingHeaderVerbatim(rating: rating, toCdMessage: cdMessage)
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
