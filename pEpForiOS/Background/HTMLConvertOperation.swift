//
//  HTMLConvertOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 11/08/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import MessageModel

/**
 Finds message that only contains html and creates a text version of it.
 */
open class HTMLConvertOperation: BaseOperation {
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

            guard let messages = CdMessage.all(
                with: NSCompoundPredicate(
                    andPredicateWithSubpredicates:
                    [CdMessage.basicMessagePredicate(),
                     predicateHasHTML, predicateHasNoLongMessage])) else {
                return
            }

            var modelChanged = false

            for m in messages {
                guard let message = m as? CdMessage else {
                    Log.warn(component: self.comp,
                             content: "Could not cast message to CdMessage type")
                    continue
                }
                if let htmlString = message.longMessageFormatted {
                    message.longMessage = htmlString.extractTextFromHTML()
                    modelChanged = true
                }
            }

            if modelChanged {
                Record.save()
            }
        }
    }
}
