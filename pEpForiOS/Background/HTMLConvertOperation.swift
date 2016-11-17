//
//  HTMLConvertOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 11/08/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

import MessageModel

/**
 Finds email that only contain html and creates a text version of it.
 */
open class HTMLConvertOperation: BaseOperation {
    let comp = "HTMLConvertOperation"
    let coreDataUtil: CoreDataUtil

    public init(coreDataUtil: CoreDataUtil) {
        self.coreDataUtil = coreDataUtil
    }

    open override func main() {
        let context = coreDataUtil.privateContext()
        context.perform() {
            let predicateHasHTML = NSPredicate.init(
                format: "longMessageFormatted != nil or longMessageFormatted != %@", "")
            let predicateHasNoLongMessage = NSPredicate.init(
                format: "longMessage == nil or longMessage == %@", "")

            guard let mails = MessageModel.CdMessage.all(
                with: NSCompoundPredicate(
                    andPredicateWithSubpredicates:
                    [MessageModel.CdMessage.basicMessagePredicate(),
                     predicateHasHTML, predicateHasNoLongMessage])) else {
                return
            }

            var modelChanged = false

            for m in mails {
                guard let mail = m as? MessageModel.CdMessage else {
                    Log.warn(component: self.comp, "Could not cast mail to Message")
                    continue
                }
                if let htmlString = mail.longMessageFormatted {
                    mail.longMessage = htmlString.extractTextFromHTML()
                    modelChanged = true
                }
            }

            if modelChanged {
                Record.save()
            }
        }
    }
}
