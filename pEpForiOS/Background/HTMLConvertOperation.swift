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
open class HTMLConvertOperation: BaseOperation {
    let comp = "HTMLConvertOperation"
    let coreDataUtil: ICoreDataUtil

    public init(coreDataUtil: ICoreDataUtil) {
        self.coreDataUtil = coreDataUtil
    }

    /**
     Debugging only, removes longMessage from all mails that also have longMessageFormatted.
     */
    func removeTextFromMails(_ model: Model) {
        let predicateHasHTML = NSPredicate.init(
            format: "longMessageFormatted != nil and longMessageFormatted != %@", "")
        let predicateHasLongMessage = NSPredicate.init(
            format: "longMessage != nil and longMessage != %@", "")
        let predicateColor = NSPredicate.init(format: "pepColorRating != nil")
        let predicateBodyFetched = NSPredicate.init(format: "bodyFetched == 1")

        guard let mails = model.entitiesWithName(
            Message.entityName(),
            predicate: NSCompoundPredicate.init(
                andPredicateWithSubpredicates: [predicateHasHTML, predicateHasLongMessage,
                    predicateColor, predicateBodyFetched]),
            sortDescriptors: [NSSortDescriptor.init(key: "receivedDate", ascending: true)])
            else {
                return
        }

        var modelChanged = false

        for m in mails {
            guard let mail = m as? Message else {
                Log.warnComponent(self.comp, "Could not cast mail to Message")
                continue
            }
            mail.longMessage = nil
            modelChanged = true
        }

        if modelChanged {
            model.save()
        }
    }

    open override func main() {
        let context = coreDataUtil.privateContext()
        context.perform() {
            let model = Model.init(context: context)

            let pBasic = model.basicMessagePredicate()
            let predicateHasHTML = NSPredicate.init(
                format: "longMessageFormatted != nil or longMessageFormatted != %@", "")
            let predicateHasNoLongMessage = NSPredicate.init(
                format: "longMessage == nil or longMessage == %@", "")

            guard let mails = model.entitiesWithName(Message.entityName(),
                predicate: NSCompoundPredicate.init(
                    andPredicateWithSubpredicates: [pBasic, predicateHasHTML,
                        predicateHasNoLongMessage]),
                sortDescriptors: [NSSortDescriptor.init(key: "receivedDate", ascending: true)])
                else {
                    return
            }

            var modelChanged = false

            for m in mails {
                guard let mail = m as? Message else {
                    Log.warnComponent(self.comp, "Could not cast mail to Message")
                    continue
                }
                if let htmlString = mail.longMessageFormatted {
                    mail.longMessage = htmlString.extractTextFromHTML()
                    modelChanged = true
                }
            }

            if modelChanged {
                model.save()
            }
        }
    }
}
