//
//  DecryptMessagesOperation.swift
//  pEpForiOS
//
//  Created by hernani on 13/06/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import MessageModel

open class DecryptMessagesOperation: ConcurrentBaseOperation {
    open var numberOfMessagesDecrypted = 0

    open override func main() {
        let context = Record.Context.background
        context.perform() {
            let session = PEPSession()

            guard let messages = CdMessage.all(
                with: CdMessage.unencryptedMessagesPredicate(),
                orderedBy: [NSSortDescriptor(key: "received", ascending: true)],
                in: context) as? [CdMessage] else {
                    self.markAsFinished()
                    return
            }

            var modelChanged = false
            for message in messages {
                var outgoing = false
                let folderTypeNum = message.parent?.folderType
                if let folderType = FolderType.fromInt(folderTypeNum!) {
                    outgoing = folderType.isOutgoing()
                } else {
                    outgoing = false
                }

                let pepMessage = PEPUtil.pEp(cdMessage: message, outgoing: outgoing)
                var pepDecryptedMessage: NSDictionary? = nil
                var keys: NSArray?
                let color = session.decryptMessageDict(
                    pepMessage, dest: &pepDecryptedMessage, keys: &keys)
                Log.info(component: self.comp,
                         content: "Decrypted message \(message.logString()) with color \(color)")

                self.numberOfMessagesDecrypted += 1

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
                    modelChanged = true
                    break
                case PEP_rating_unreliable,
                     PEP_rating_mistrust,
                     PEP_rating_under_attack,
                     PEP_rating_reliable,
                     PEP_rating_reliable,
                     PEP_rating_trusted,
                     PEP_rating_trusted,
                     PEP_rating_trusted_and_anonymized,
                     PEP_rating_fully_anonymous:
                    if let decrypted = pepDecryptedMessage {
                        message.update(pEpMessage: decrypted as! PEPMessage, pepColorRating: color)
                        modelChanged = true
                    }
                    break
                default:
                    Log.warn(
                        component: self.comp,
                        content: "No default action for decrypted message \(message.logString())")
                    break
                }
            }
            if modelChanged {
                Record.saveAndWait()
            }
            self.markAsFinished()
        }
    }
}
