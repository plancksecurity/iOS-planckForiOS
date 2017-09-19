//
//  DecryptMessagesOperation.swift
//  pEpForiOS
//
//  Created by hernani on 13/06/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import MessageModel

import CoreData

public protocol DecryptMessagesOperationProtocol: class {
    /**
     Called whenever a message just got decrypted. Useful for tests.
     */
    func decrypted(originalCdMessage: CdMessage, decryptedMessageDict: NSDictionary?,
                   rating: PEP_rating, keys: [String])
}

public class DecryptMessagesOperation: ConcurrentBaseOperation {
    public weak var delegate: DecryptMessagesOperationProtocol?

    public override func main() {
        let context = Record.Context.background
        context.perform() {
            let session = PEPSessionCreator.shared.newSession()

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

                let pepMessage = PEPUtil.pEp(cdMessage: cdMessage, outgoing: outgoing)
                var pEpDecryptedMessage: NSDictionary? = nil
                var keys: NSArray?
                Log.info(component: self.comp,
                         content: "Will decrypt \(cdMessage.logString())")
                let rating = session.decryptMessageDict(
                    pepMessage, dest: &pEpDecryptedMessage, keys: &keys)
                Log.info(component: self.comp,
                         content: "Decrypted message \(cdMessage.logString()) with color \(rating)")

                let theKeys = Array(keys ?? NSArray()) as? [String] ?? []

                self.delegate?.decrypted(
                    originalCdMessage: cdMessage, decryptedMessageDict: pEpDecryptedMessage,
                    rating: rating, keys: theKeys)

                switch rating {
                case PEP_rating_undefined,
                     PEP_rating_cannot_decrypt,
                     PEP_rating_have_no_key,
                     PEP_rating_b0rken:
                    // Do nothing, try to decrypt again later though
                    break
                case PEP_rating_unencrypted,
                     PEP_rating_unencrypted_for_some:
                    // Set the color, nothing else to update
                    cdMessage.pEpRating = Int16(rating.rawValue)
                    self.updateMessage(cdMessage: cdMessage, keys: theKeys, context: context)
                    break
                case PEP_rating_unreliable,
                     PEP_rating_mistrust,
                     PEP_rating_reliable,
                     PEP_rating_reliable,
                     PEP_rating_trusted,
                     PEP_rating_trusted,
                     PEP_rating_trusted_and_anonymized,
                     PEP_rating_fully_anonymous:
                    self.updateWholeMessage(
                        pEpDecryptedMessage: pEpDecryptedMessage,
                        pEpColorRating: rating, cdMessage: cdMessage,
                        keys: theKeys, underAttack: false, context: context)
                    break
                case PEP_rating_under_attack:
                    self.updateWholeMessage(
                        pEpDecryptedMessage: pEpDecryptedMessage,
                        pEpColorRating: rating, cdMessage: cdMessage,
                        keys: theKeys, underAttack: true, context: context)
                default:
                    Log.warn(
                        component: self.comp,
                        content: "No default action for decrypted message \(cdMessage.logString())")
                    break
                }
            }
            self.markAsFinished()
        }
    }

    /**
     Updates message bodies (after decryption), then calls `updateMessage`.
     */
    func updateWholeMessage(
        pEpDecryptedMessage: NSDictionary?,
        pEpColorRating: PEP_rating,
        cdMessage: CdMessage, keys: [String],
        underAttack: Bool,
        context: NSManagedObjectContext) {
        if let decrypted = pEpDecryptedMessage as? PEPMessage {
            cdMessage.update(pEpMessage: decrypted, pEpColorRating: pEpColorRating)
            cdMessage.underAttack = underAttack
            self.updateMessage(cdMessage: cdMessage, keys: keys, context: context)
        } else {
            Log.shared.errorAndCrash(
                component: #function,
                errorString:"Decrypt with rating, but nil message")
        }
    }

    /**
     Updates the given key list for the message and notifies delegates.
     */
    func updateMessage(cdMessage: CdMessage, keys: [String], context: NSManagedObjectContext) {
        cdMessage.updateKeyList(keys: keys)
        context.saveAndLogErrors()
        cdMessage.updateDecrypted()
    }
}
