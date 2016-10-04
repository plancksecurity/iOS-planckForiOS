//
//  OutgoingMessageColorOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 18/07/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import CoreData

class OutgoingMessageColorOperation: Operation {
    /**
     Input: The pEp mail dictionary to check.
     */
    var pepMail: PEPMail?

    /**
     Output: The pEp color rating for the mail.
     */
    var pepColorRating: PEP_rating?

    override func main() {
        if let mail = pepMail {
            pepColorRating = nil
            let session = PEPSession.init()
            pepColorRating = session.outgoingMessageColor(mail as! [AnyHashable : Any])
        }
    }
}
