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
        context.perform() {
            guard let messages = CdMessage.all(
                predicate: CdMessage.unknownToPepMessagesPredicate(),
                orderedBy: [NSSortDescriptor(key: "received", ascending: true)],
                in: context) as? [CdMessage] else {
                    self.markAsFinished()
                    return
            }

            for cdMessage in messages {
                var outgoing = false
                if let folderType = cdMessage.parent?.folderType {
                    outgoing = folderType.isOutgoing()
                }

                let pepMessage = PEPUtil.pEpDict(
                    cdMessage: cdMessage, outgoing: outgoing).mutableDictionary()
                var keys: NSArray?
                Log.info(component: self.comp,
                         content: "Will decrypt \(cdMessage.logString())")
                let session = PEPSession()

                var rating = PEP_rating_undefined
                do {
                    let pEpDecryptedMessage = try session.decryptMessageDict(
                        pepMessage, flags: nil, rating: &rating, extraKeys: &keys, status: nil)
                        as NSDictionary
                    handleDecryptionSuccess(cdMessage: cdMessage,
                                            pEpDecryptedMessage: pEpDecryptedMessage,
                                            rating: rating,
                                            keys: keys)
                } catch let error as NSError {
                    // log, and try again next time
                    Log.error(component: #function, error: error)
                }
            }
            self.markAsFinished()
        }

        func handleDecryptionSuccess(cdMessage: CdMessage, pEpDecryptedMessage: NSDictionary,
                                     rating: PEP_rating, keys: NSArray?) {
            let theKeys = Array(keys ?? NSArray()) as? [String] ?? []

            self.delegate?.decrypted(
                originalCdMessage: cdMessage, decryptedMessageDict: pEpDecryptedMessage,
                rating: rating, keys: theKeys) // Only used in Tests. Maybe refactor out.

            updateWholeMessage(
                pEpDecryptedMessage: pEpDecryptedMessage,
                rating: rating, cdMessage: cdMessage,
                keys: theKeys, context: context)
        }
    }

    /**
     Updates message bodies (after decryption), then calls `updateMessage`.
     */
    func updateWholeMessage(
        pEpDecryptedMessage: NSDictionary?,
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
            cdMessage.update(pEpMessageDict: decrypted, pEpColorRating: rating)
            updateMessage(cdMessage: cdMessage, keys: keys, context: context)
        } else {
            cdMessage.update(rating: rating)
        }
    }

    /**
     Updates the given key list for the message and notifies delegates.
     */
    func updateMessage(cdMessage: CdMessage, keys: [String], context: NSManagedObjectContext) {
        cdMessage.updateKeyList(keys: keys)
        context.saveAndLogErrors()
        notifyDelegate(messageUpdated: cdMessage)
    }

    private func notifyDelegate(messageUpdated cdMessage: CdMessage) {
        guard let message = cdMessage.message() else {
            Log.shared.errorAndCrash(component: #function, errorString: "Error converting CDMesage")
            return
        }
        MessageModelConfig.messageFolderDelegate?.didCreate(messageFolder: message)
    }
}
