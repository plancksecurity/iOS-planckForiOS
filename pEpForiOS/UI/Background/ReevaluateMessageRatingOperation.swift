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

    init(message: Message) {
        self.message = message
    }

    open override func main() {
        let context = Record.Context.background
        context.perform {
            self.reevalute(context: context)
            self.markAsFinished()
        }
    }

    func reevalute(context: NSManagedObjectContext) {
        guard let cdMsg = CdMessage.search(message: message) else {
            addError(ReevaluationError.noMessageFound)
            return
        }
        let session = PEPSession()
        let pepMessage = cdMsg.pEpMessage()
        let newRating = session.reEvaluateMessageRating(pepMessage)
        cdMsg.pEpRating = Int16(newRating.rawValue)
        Record.saveAndWait(context: context)
        message.pEpRatingInt = Int(newRating.rawValue)
    }
}
