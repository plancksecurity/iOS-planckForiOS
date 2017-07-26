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
    let message: Message
    lazy var queue = LimitedOperationQueue()
    weak var delegate: RatingReEvaluatorDelegate?

    init(message: Message) {
        self.message = message
    }

    func reevaluateRating() {
        let op = ReevaluateMessageRatingOperation(message: message)
        op.completionBlock = {
            op.completionBlock = nil
            if !op.hasErrors() {
                self.delegate?.ratingChanged(message: self.message)
            }
        }
        queue.addOperation(op)
    }
}
