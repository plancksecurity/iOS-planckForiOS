//
//  DecryptMessagesOperation.swift
//  pEpForiOS
//
//  Created by hernani on 13/06/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import MessageModel

public class DecryptMessagesOperation: ConcurrentBaseOperation {
    public var numberOfMessagesDecrypted = 0

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

            for message in messages {
                var outgoing = false
                if let folderType = message.parent?.folderType {
                    outgoing = folderType.isOutgoing()
                }

                let pepMessage = PEPUtil.pEp(cdMessage: message, outgoing: outgoing)
                var pEpDecryptedMessage: NSDictionary? = nil
                var keys: NSArray?
                Log.info(component: self.comp,
                         content: "Will decrypt \(message.logString())")
                let color = session.decryptMessageDict(
                    pepMessage, dest: &pEpDecryptedMessage, keys: &keys)
                Log.info(component: self.comp,
                         content: "Decrypted message \(message.logString()) with color \(color)")

                self.numberOfMessagesDecrypted += 1
                let theKeys = Array(keys ?? NSArray()) as? [String] ?? []

                switch color {
                case PEP_rating_undefined,
                     PEP_rating_cannot_decrypt,
                     PEP_rating_have_no_key,
                     PEP_rating_b0rken:
                    // Do nothing, try to decrypt again later though
                    break
                case PEP_rating_unencrypted,
                     PEP_rating_unencrypted_for_some:
                    // Set the color, nothing else to update
                    message.pEpRating = Int16(color.rawValue)
                    self.updateMessage(cdMessage: message, keys: theKeys)
                    break
                case PEP_rating_unreliable,
                     PEP_rating_mistrust,
                     PEP_rating_reliable,
                     PEP_rating_reliable,
                     PEP_rating_trusted,
                     PEP_rating_trusted,
                     PEP_rating_trusted_and_anonymized,
                     PEP_rating_fully_anonymous:
                    if let decrypted = pEpDecryptedMessage as? PEPMessage {
                        message.update(pEpMessage: decrypted, pEpColorRating: color)
                        self.updateMessage(cdMessage: message, keys: theKeys)
                    } else {
                        Log.shared.errorAndCrash(component: #function,
                                                 errorString:"Not sure if this is supposed to happen even I think it's not. If it is, remove the else block or lower the log ")
                    }
                    break
                case PEP_rating_under_attack:
                    if let decrypted = pEpDecryptedMessage as? PEPMessage {
                        message.update(pEpMessage: decrypted, pEpColorRating: color)
                        message.underAttack = true
                        self.updateMessage(cdMessage: message, keys: theKeys)
                    } else {
                        Log.shared.errorAndCrash(component: #function,
                                                 errorString:"Not sure if this is supposed to happen even I think it's not. If it is, remove the else block or lower the log ")
                    }
                default:
                    Log.warn(
                        component: self.comp,
                        content: "No default action for decrypted message \(message.logString())")
                    break
                }
            }
            self.markAsFinished()
        }
    }

    /**
     Updates the given key list for the message, puts rating into optional fields
     and notifies delegates.
     */
    func updateMessage(cdMessage: CdMessage, keys: [String]) {
        cdMessage.updateKeyList(keys: keys)
        Record.saveAndWait()
        cdMessage.updateDecrypted()
    }
}
