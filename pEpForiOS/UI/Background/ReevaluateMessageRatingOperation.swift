//
//  ReevaluateMessageRatingOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 17/02/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit

import MessageModel

/**
 Reevaluate the rating for messages whose trust status has changed (that is,
 an identity involved in the message has changed the trust status).
 */
class ReevaluateMessageRatingOperation: Operation {
    let message: Message

    init(message: Message) {
        self.message = message
    }

    open override func main() {
        // TODO: This is a hack. Has to be replaced by whatever the outcome
        // of ENGINE-179 will be. Leads to errors, but at least you have something
        // to see in the UI.
        if let from = message.from {
            message.pEpRatingInt = Int(from.pEpRating().rawValue)
            message.save()
        }
    }
}
