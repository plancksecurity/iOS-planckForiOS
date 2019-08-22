//
//  ReevaluateMessageRatingOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 17/02/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit
import CoreData
import pEpIOSToolbox
import MessageModel
import PEPObjCAdapterFramework

/**
 Reevaluate the rating for messages whose trust status has changed (that is,
 an identity involved in the message has changed the trust status).
 */
class ReevaluateMessageRatingOperation: ConcurrentBaseOperation {
    enum ReevaluationError: Error {
        case noMessageFound
    }

    var cdMessage: CdMessage?

    init(parentName: String = #function,
         message: Message,
         context: NSManagedObjectContext? = nil) {
        super.init(parentName: parentName, context: context)
        guard let msgObjId = message.cdMessage()?.objectID else {
            Log.shared.errorAndCrash("No Object ID")
            return
        }
        privateMOC.performAndWait { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            let potentialMessage = try? privateMOC.existingObject(with: msgObjId)
            me.cdMessage = potentialMessage as? CdMessage
        }
    }

    open override func main() {
        if isCancelled {
            markAsFinished()
            return
        }
        reEvaluate()
        markAsFinished()
    }

    func reEvaluate() {
        privateMOC.performAndWait { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            guard let cdMsg = me.cdMessage else {
                addError(ReevaluationError.noMessageFound)
                return
            }
            let pEpSession = PEPSession()
            let pepMessage = cdMsg.pEpMessage()
            do {
                let keys = cdMsg.keysFromDecryption?.array as? [String] // Needs to be extented when implementing "Extra Keys" feature to take X-KeyList header into account
                var newRating = PEPRating.undefined
                try pEpSession.reEvaluateMessage(pepMessage,
                                                 xKeyList: keys,
                                                 rating: &newRating,
                                                 status: nil)
                cdMsg.pEpRating = Int16(newRating.rawValue)
                privateMOC.saveAndLogErrors()
            } catch let error as NSError {
                Log.shared.log(error: error)
            }
        }
    }
}
