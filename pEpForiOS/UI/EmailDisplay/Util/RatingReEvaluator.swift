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
    let parentName: String

    init(parentName: String = #function, message: Message) {
        self.parentName = parentName
        self.message = message
    }

    func reevaluateRating() {
        let op = ReevaluateMessageRatingOperation(parentName: parentName, message: message)
        op.completionBlock = {
            if !op.hasErrors() {
                self.delegate?.ratingChanged(message: self.message)
            }
        }
        queue.addOperation(op)
    }
}
