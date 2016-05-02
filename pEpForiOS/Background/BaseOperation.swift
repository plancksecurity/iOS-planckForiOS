//
//  BaseOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 15/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation
import CoreData

class BaseOperation: NSOperation {

    let grandOperator: IGrandOperator
    var myFinished: Bool = false

    init(grandOperator: IGrandOperator) {
        self.grandOperator = grandOperator
        super.init()
    }

    override var finished: Bool {
        return myFinished
    }

    func markAsFinished() {
        willChangeValueForKey("isFinished")
        myFinished = true
        didChangeValueForKey("isFinished")
    }

    func modelForContext(context: NSManagedObjectContext) -> IModel {
        return Model.init(context: context)
    }
}