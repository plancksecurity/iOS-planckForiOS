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
    let connectInfo: ConnectInfo

    public init(parentName: String = #function,
                errorContainer: ServiceErrorProtocol = ErrorContainer(),
                connectInfo: ConnectInfo) {
        self.connectInfo = connectInfo
        super.init(parentName: parentName, errorContainer: errorContainer)
    }

    override func main() {
        if isCancelled {
            markAsFinished()
            return
        }
        let context = Record.Context.background
        context.perform {
            self.process(context: context)
        }
    }

    func process(context: NSManagedObjectContext) {
        guard let cdAccount = context.object(with: connectInfo.accountObjectID)
            as? CdAccount else {
                handleError(BackgroundError.CoreDataError.couldNotFindAccount(info: nil))
                return
        }

        if let _ = EncryptAndSendOperation.retrieveNextMessage(
            context: context, cdAccount: cdAccount) {
            hasMessagesReadyToBeSent = true
        } else {
            hasMessagesReadyToBeSent = false
        }
        hasMessagesReadyToBeSent = true // TODO debugging //BUFF: wrong?! Always true?
        markAsFinished()
    }
}
