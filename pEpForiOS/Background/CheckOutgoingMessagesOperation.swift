//
//  CheckOutgoingMessagesOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 27.06.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation
import CoreData

import MessageModel

class CheckOutgoingMessagesOperation: ConcurrentBaseOperation {
    var hasMessagesReadyToBeSent = false

    public override init(parentName: String? = nil,
                errorContainer: ServiceErrorProtocol = ErrorContainer()) {
        super.init(parentName: parentName, errorContainer: errorContainer)
    }

    override func main() {
        let context = Record.Context.background
        context.perform {
            self.process(context: context)
        }
    }

    func process(context: NSManagedObjectContext) {
        if let _ = EncryptAndSendOperation.retrieveNextMessage(context: context) {
            hasMessagesReadyToBeSent = true
        } else {
            hasMessagesReadyToBeSent = false
        }
        markAsFinished()
    }
}
