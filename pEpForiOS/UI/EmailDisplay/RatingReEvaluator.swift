//
//  RatingReEvaluator.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 17/02/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit

import MessageModel

public protocol RatingReEvaluatorDelegate: class {
    func ratingChanged(message: Message)
}

class RatingReEvaluator {
    let session: PEPSession
    let message: Message
    lazy var queue = LimitedOperationQueue()
    weak var delegate: RatingReEvaluatorDelegate?
    let parentName: String

    init(parentName: String, message: Message, session: PEPSession) {
        self.parentName = parentName
        self.message = message
        self.session = session
    }

    func reevaluateRating() {
        let op = ReevaluateMessageRatingOperation(parentName: parentName, message: message, session: session)
        op.completionBlock = {
            op.completionBlock = nil
            if !op.hasErrors() {
                self.delegate?.ratingChanged(message: self.message)
            }
        }
        queue.addOperation(op)
    }
}
