//
//  OutgoingMessageColorOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 18/07/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

class OutgoingMessageColorOperation: Operation {
    /**
     Input: The pEp message dictionary to check.
     */
    var pepMessage: PEPMessage?

    /**
     Output: The pEp color rating for the message.
     */
    var pepColorRating: PEP_rating?

    override func main() {
        if let message = pepMessage {
            pepColorRating = nil
            let session = PEPSession.init()
            pepColorRating = session.outgoingMessageColor(message)
        }
    }
}
