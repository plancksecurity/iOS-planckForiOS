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
        if isCancelled {
            markAsFinished()
            return
        }
        let theContext = Record.Context.background
        theContext.perform {
            self.reEvaluate(context: theContext)
            self.markAsFinished()
        }
    }

    func reEvaluate(context: NSManagedObjectContext) {
        guard let cdMsg = CdMessage.search(message: message) else {
            addError(ReevaluationError.noMessageFound)
            return
        }
        let theSession = PEPSession()
        let pepMessage = cdMsg.pEpMessageDict()
        do {
            let keys = cdMsg.keysFromDecryption?.array as? [String] // Needs to be extented when implementing "Extra Keys" feature to take X-KeyList header into account
            var newRating = PEP_rating_undefined
            try theSession.reEvaluateMessageDict(pepMessage,
                                                 xKeyList: keys,
                                                 rating: &newRating,
                                                 status: nil)
            context.updateAndSave(object: cdMsg) {
                cdMsg.pEpRating = Int16(newRating.rawValue)
            }

            context.saveAndLogErrors()
            message.pEpRatingInt = Int(newRating.rawValue)
        } catch let error as NSError {
            Log.error(component: #function, error: error)
        }
    }
}
