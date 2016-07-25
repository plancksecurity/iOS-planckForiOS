//
//  DecryptMailOperation.swift
//  pEpForiOS
//
//  Created by hernani on 13/06/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation

public class DecryptMailOperation: BaseOperation {
    let comp = "DecryptMailOperation"
    let coreDataUtil: ICoreDataUtil

    public init(coreDataUtil: ICoreDataUtil) {
        self.coreDataUtil = coreDataUtil
    }

    public override func main() {
        let context = coreDataUtil.privateContext()
        context.performBlock() {
            let model = Model.init(context: context)
            let session = PEPSession.init()

            guard let mails = model.entitiesWithName(Message.entityName(),
                predicate: NSPredicate.init(format: "pepColor == nil"),
                sortDescriptors: [NSSortDescriptor.init(key: "originationDate", ascending: true)])
                else {
                    return
            }

            for m in mails {
                guard let mail = m as? IMessage else {
                    Log.warnComponent(self.comp, "Could not cast mail to IMessage")
                    continue
                }
                let pepMail = PEPUtil.pepMail(mail)
                var pepDecryptedMail: NSDictionary?
                var keys: NSArray?
                let color = session.decryptMessageDict(
                    pepMail, dest: &pepDecryptedMail, keys: &keys)
                Log.warnComponent(self.comp,
                    "Decrypted mail \(mail.logString()) with color \(color)")

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
                    mail.pepColor = NSNumber.init(int: color.rawValue)
                    break
                case PEP_rating_unreliable,
                PEP_rating_mistrust,
                PEP_rating_red,
                PEP_rating_under_attack,
                PEP_rating_reliable,
                PEP_rating_yellow,
                PEP_rating_reliable,
                PEP_rating_trusted,
                PEP_rating_green,
                PEP_rating_trusted,
                PEP_rating_trusted_and_anonymized,
                PEP_rating_fully_anonymous:
                    PEPUtil.updateDecryptedMessage(mail, fromPepMail: pepDecryptedMail as! PEPMail,
                        pepColorRating: color, model: model)
                    break
                // TODO: Again, why is the default needed when all cases are there?
                default:
                    Log.warnComponent(self.comp,
                        "No default action for decrypted mail \(mail.logString())")
                }
            }
            model.save()
        }
    }
}