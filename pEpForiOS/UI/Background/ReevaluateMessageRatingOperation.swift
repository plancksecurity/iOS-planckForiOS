//
//  ReevaluateMessageRatingOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 17/02/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit
import CoreData

import MessageModel

/**
 Reevaluate the rating for messages whose trust status has changed (that is,
 an identity involved in the message has changed the trust status).
 */
class ReevaluateMessageRatingOperation: ConcurrentBaseOperation {
    enum ReevaluationError: Error {
        case noMessageFound
    }

    let message: Message

    init(parentName: String = #function, message: Message) {
        self.message = message
        super.init(parentName: parentName)
    }

    open override func main() {
        let theContext = Record.Context.background
        theContext.perform {
            self.reevaluate(context: theContext)
            self.markAsFinished()
        }
    }

    func reevaluate(context: NSManagedObjectContext) {
        guard let cdMsg = CdMessage.search(message: message) else {
            addError(ReevaluationError.noMessageFound)
            return
        }
        let theSession = PEPSession()
        let pepMessage = cdMsg.pEpMessageDict()
        let newRating = theSession.reEvaluateMessageRating(pepMessage)

        context.updateAndSave(object: cdMsg) {
            cdMsg.pEpRating = Int16(newRating.rawValue)
        }

        context.saveAndLogErrors()
        message.pEpRatingInt = Int(newRating.rawValue)
    }
}
