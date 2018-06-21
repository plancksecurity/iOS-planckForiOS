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
                let originalRating = cdMessage.pEpRating

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
                    handleDecryptionSuccess(cdMessage: cdMessage,
                                            pEpDecryptedMessage: pEpDecryptedMessage,
                                            originalRating: originalRating,
                                            rating: rating,
                                            keys: keys)
                } catch let error as NSError {
                    // log, and try again next time
                    Log.error(component: #function, error: error)
                }
            }
        }

        func handleDecryptionSuccess(cdMessage: CdMessage,
                                     pEpDecryptedMessage: NSDictionary,
                                     originalRating: Int16,
                                     rating: PEP_rating,
                                     keys: NSArray?) {
            let theKeys = Array(keys ?? NSArray()) as? [String] ?? []

            self.delegate?.decrypted(
                originalCdMessage: cdMessage, decryptedMessageDict: pEpDecryptedMessage,
                rating: rating, keys: theKeys) // Only used in Tests. Maybe refactor out.

            updateWholeMessage(
                pEpDecryptedMessage: pEpDecryptedMessage,
                originalRating: originalRating,
                rating: rating,
                cdMessage: cdMessage,
                keys: theKeys,
                context: context)
        }
    }

    /**
     Updates message bodies (after decryption), then calls `updateMessage`.
     */
    func updateWholeMessage(
        pEpDecryptedMessage: NSDictionary?,
        originalRating: Int16,
        rating: PEP_rating,
        cdMessage: CdMessage, keys: [String],
        context: NSManagedObjectContext) {
        cdMessage.underAttack = rating.isUnderAttack()
        if rating.shouldUpdateMessageContent() {
            guard let decrypted = pEpDecryptedMessage as? PEPMessageDict else {
                Log.shared.errorAndCrash(
                    component: #function,
                    errorString:"should update message with rating \(rating), but nil message")
                return
            }
            cdMessage.update(pEpMessageDict: decrypted, rating: rating)
            updateMessage(cdMessage: cdMessage, keys: keys, context: context)
        } else {
            if rating.rawValue != originalRating {
                cdMessage.update(rating: rating)
                saveAndNotify(cdMessage: cdMessage, context: context)
            }
        }
    }

    func saveAndNotify(cdMessage: CdMessage, context: NSManagedObjectContext) {
        context.saveAndLogErrors()
        notifyDelegate(messageUpdated: cdMessage)
    }

    /**
     Updates the given key list for the message and notifies delegates.
     */
    func updateMessage(cdMessage: CdMessage, keys: [String], context: NSManagedObjectContext) {
        cdMessage.updateKeyList(keys: keys)
        saveAndNotify(cdMessage: cdMessage, context: context)
    }

    private func notifyDelegate(messageUpdated cdMessage: CdMessage) {
        guard let message = cdMessage.message() else {
            Log.shared.errorAndCrash(component: #function, errorString: "Error converting CDMesage")
            return
        }
        MessageModelConfig.messageFolderDelegate?.didCreate(messageFolder: message)
    }
}
