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

    public override func main() {
        if isCancelled {
            markAsFinished()
            return
        }
        let context = privateMOC
        context.perform() { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash(component: #function, errorString: "Lost myself")
                return
            }
            defer {
                me.markAsFinished()
            }
            guard let cdMessages = CdMessage.all(
                predicate: CdMessage.unknownToPepMessagesPredicate(),
                orderedBy: [NSSortDescriptor(key: "received", ascending: true)],
                in: context) as? [CdMessage] else {
                    return
            }

            for cdMessage in cdMessages {
                guard let message = cdMessage.message() else {
                    Log.shared.errorAndCrash(component: #function, errorString: "No message")
                    continue
                }
                if me.isCancelled {
                    break
                }
                //
                let ratingBeforeEngine = cdMessage.pEpRating

                var outgoing = false
                if let folderType = cdMessage.parent?.folderType {
                    outgoing = folderType.isOutgoing()
                }

                let pepMessage = PEPUtil.pEpDict(
                    cdMessage: cdMessage, outgoing: outgoing).mutableDictionary()
                var keys: NSArray?
                Log.info(component: me.comp,
                         content: "Will decrypt \(cdMessage.logString())")
                let session = PEPSession()

                var rating = PEP_rating_undefined
                let pEpDecryptedMessage: NSDictionary
                do {
                    // (This nasty if clause is a workaround to what I consider as a Swift 4.1 bug,
                    // causing an error "generic parameter "wrapped" could not be inferred".
                    // The only difference is the `flags`parameter.)
                    if message.isOnTrustedServer {
                        pEpDecryptedMessage = try session.decryptMessageDict(pepMessage,
                                                                             flags: nil,
                                                                             rating: &rating,
                                                                             extraKeys: &keys,
                                                                             status: nil)
                            as NSDictionary
                    } else {
                        var flags = PEP_decrypt_flag_untrusted_server
                        pEpDecryptedMessage = try session.decryptMessageDict(pepMessage,
                                                                             flags: &flags,
                                                                             rating: &rating,
                                                                             extraKeys: &keys,
                                                                             status: nil)
                            as NSDictionary
                    }
                    me.handleDecryptionSuccess(cdMessage: cdMessage,
                                               pEpDecryptedMessage: pEpDecryptedMessage,
                                               ratingBeforeEngine: ratingBeforeEngine,
                                               rating: rating,
                                               keys: keys)
                } catch let error as NSError {
                    // log, and try again next time
                    Log.error(component: #function, error: error)
                }
            }
        }
    }

    private func handleDecryptionSuccess(cdMessage: CdMessage,
                                         pEpDecryptedMessage: NSDictionary,
                                         ratingBeforeEngine: Int16,
                                         rating: PEP_rating,
                                         keys: NSArray?) {
        let theKeys = Array(keys ?? NSArray()) as? [String] ?? []

        // Only used in Tests. Maybe refactor out.
        self.delegate?.decrypted(originalCdMessage: cdMessage,
                                 decryptedMessageDict: pEpDecryptedMessage,
                                 rating: rating,
                                 keys: theKeys)

        updateWholeMessage(pEpDecryptedMessage: pEpDecryptedMessage,
                           ratingBeforeEngine: ratingBeforeEngine,
                           rating: rating,
                           cdMessage: cdMessage,
                           keys: theKeys)
        handleReUploadAndNotify(cdMessage: cdMessage, rating: rating)
    }

    /**
     Updates message bodies (after decryption), then calls `updateMessage`.
     */
    private func updateWholeMessage(pEpDecryptedMessage: NSDictionary?,
                                    ratingBeforeEngine: Int16,
                                    rating: PEP_rating,
                                    cdMessage: CdMessage,
                                    keys: [String]) {
        guard rating.shouldUpdateMessageContent() else {
            if rating.rawValue != ratingBeforeEngine {
                cdMessage.update(rating: rating)
                saveAndNotify(cdMessage: cdMessage)
            }
            return
        }

        cdMessage.underAttack = rating.isUnderAttack()
        guard let decrypted = pEpDecryptedMessage as? PEPMessageDict else {
            Log.shared.errorAndCrash(
                component: #function,
                errorString:"should update message with rating \(rating), but nil message")
            return
        }
        updateMessage(cdMessage: cdMessage, keys: keys, pEpMessageDict: decrypted, rating: rating)
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

    private func handleReUploadIfRequired(cdMessage: CdMessage,
                                          rating: PEP_rating) throws -> Bool {
        guard let message = cdMessage.message() else {
            Log.shared.errorAndCrash(component: #function, errorString: "No Message")
            throw BackgroundError.GeneralError.illegalState(info: "No Message")
        }
        if !message.isOnTrustedServer || // The only currently supported case for re-upload is trusted server.
            message.wasAlreadyUnencrypted { // If the message was not encrypted, there is no reason to re-upload it.
            return false
        }
        let messageCopyForReupload = Message(message: message)
        setOriginalRatingHeader(rating: rating, toMessage: messageCopyForReupload)
        messageCopyForReupload.save()
        message.imapMarkDeleted()
        return true
    }

    private func setOriginalRatingHeader(rating: PEP_rating, toMessage cdMessage: CdMessage) {
        guard let message = cdMessage.message() else {
            Log.shared.errorAndCrash(component: #function, errorString: "No Message")
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
        cdMessage.updateKeyList(keys: keys) //IOS-33: Why extra keys inout? Afaics we set those output keys to CdMessage and never use it anywhere (we do not set it to any optional header or such)
    }

    private func notifyDelegate(messageUpdated cdMessage: CdMessage) {
        guard let message = cdMessage.message() else {
            Log.shared.errorAndCrash(component: #function, errorString: "Error converting CDMesage")
            return
        }
        MessageModelConfig.messageFolderDelegate?.didCreate(messageFolder: message)
    }
}
