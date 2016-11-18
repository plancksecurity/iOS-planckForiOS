//
//  DecryptMailOperation.swift
//  pEpForiOS
//
//  Created by hernani on 13/06/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import MessageModel

open class DecryptMailOperation: BaseOperation {
    let comp = "DecryptMailOperation"
    let coreDataUtil: CoreDataUtil

    public init(coreDataUtil: CoreDataUtil) {
        self.coreDataUtil = coreDataUtil
    }

    open override func main() {
        let context = coreDataUtil.privateContext()
        context.perform() {
            let session = PEPSession.init()

            guard let mails = MessageModel.CdMessage.all(with:
                NSCompoundPredicate(andPredicateWithSubpredicates:
                    [MessageModel.CdMessage.basicMessagePredicate()]),orderedBy:
                [NSSortDescriptor.init(key: "receivedDate", ascending: true)]) else {
                return
            }

            var modelChanged = false
            for m in mails {
                guard let mail = m as? MessageModel.CdMessage else {
                    Log.warn(component: self.comp, "Could not cast mail to Message")
                    continue
                }

                var outgoing = false
                let folderTypeNum = mail.parent?.folderType
                if let folderType = FolderType.fromInt(folderTypeNum!) {
                    outgoing = folderType.isOutgoing()
                } else {
                    outgoing = false
                }

                let pepMail = PEPUtil.pEp(mail: mail, outgoing: outgoing)
                var pepDecryptedMail: NSDictionary? = nil
                var keys: NSArray?
                let color = session.decryptMessageDict(
                    pepMail, dest: &pepDecryptedMail, keys: &keys)
                //TODO: new method to get de logstring?
                /*Log.warn(component: self.comp,
                    "Decrypted mail \(mail.logString()) with color \(color)")*/

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
                    mail.pEpRating = Int16(color.rawValue)
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
                    if let decrypted = pepDecryptedMail {
                        PEPUtil.update(decryptedMessage: mail,
                                       fromPepMail: decrypted as! PEPMail,
                                       pepColorRating: color)
                        modelChanged = true
                    }
                    break
                // TODO: Again, why is the default needed when all cases are there?
                default:
                    break
                    //TODO: new method to get de logstring?
                    /*Log.warn(component: self.comp,
                        "No default action for decrypted mail \(mail.logString())")*/
                }
            }
            if modelChanged {
                Record.save()
            }
        }
    }
}
