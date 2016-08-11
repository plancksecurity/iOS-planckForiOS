//
//  HTMLConvertOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 11/08/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

/**
 Finds email that only contain html and creates a text version of it.
 */
public class HTMLConvertOperation: BaseOperation {
    let comp = "HTMLConvertOperation"
    let coreDataUtil: ICoreDataUtil

    public init(coreDataUtil: ICoreDataUtil) {
        self.coreDataUtil = coreDataUtil
    }

    public override func main() {
        let context = coreDataUtil.privateContext()
        context.performBlock() {
            let model = Model.init(context: context)

            let predicateHasHTML = NSPredicate.init(
                format: "longMessageFormatted != nil or longMessageFormatted != %@", "")
            let predicateNoLongMessage = NSPredicate.init(
                format: "longMessage == nil or longMessage == %@", "")
            let predicateColor = NSPredicate.init(format: "pepColorRating == nil")
            let predicateBodyFetched = NSPredicate.init(format: "bodyFetched == 1")

            guard let mails = model.entitiesWithName(Message.entityName(),
                predicate: NSCompoundPredicate.init(
                    andPredicateWithSubpredicates: [predicateHasHTML, predicateNoLongMessage,
                        predicateColor, predicateBodyFetched]),
                sortDescriptors: [NSSortDescriptor.init(key: "receivedDate", ascending: true)])
                else {
                    return
            }

            var modelChanged = false

            for m in mails {
                guard let mail = m as? IMessage else {
                    Log.warnComponent(self.comp, "Could not cast mail to IMessage")
                    continue
                }
                print("mail \(mail.subject) without text: \(mail.longMessage)")
            }

            if modelChanged {
                model.save()
            }
        }
    }
}