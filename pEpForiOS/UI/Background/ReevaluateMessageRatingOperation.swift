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
        // Implementation blocked by ENGINE-179.
        // For now, just wait a couple of seconds, then do nothing.
        sleep(2)
    }
}
