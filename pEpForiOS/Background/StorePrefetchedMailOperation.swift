//
//  StorePrefetchedMailOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 15/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import CoreData
import pEpUtilities
import MessageModel

/**
 This can be used in a queue, or directly called with ```start()```.
 */
public class StorePrefetchedMailOperation: ConcurrentBaseOperation {
    let message: CWIMAPMessage
    let accountID: NSManagedObjectID
    let messageFetchedBlock: MessageFetchedBlock?
    let messageUpdate: CWMessageUpdate

    public init(
        parentName: String = #function,
        accountID: NSManagedObjectID, message: CWIMAPMessage,
        messageUpdate: CWMessageUpdate,
        messageFetchedBlock: MessageFetchedBlock? = nil) {
        self.accountID = accountID
        self.message = message
        self.messageUpdate = messageUpdate
        self.messageFetchedBlock = messageFetchedBlock
        super.init(parentName: parentName)
    }

    override public func main() {
        if isCancelled {
            markAsFinished()
            return
        }
        let context = privateMOC
        context.perform() {
            if self.isCancelled {
                self.markAsFinished()
                return
            }
            self.storeMessage(context: context)
            self.markAsFinished()
        }
    }

    func storeMessage(context: NSManagedObjectContext) {
        guard let account = context.object(with: accountID) as? CdAccount else {
            addError(BackgroundError.CoreDataError.couldNotFindAccount(info: #function))
            return
        }
        if let msg = insertOrUpdate(pantomimeMessage: message, account: account) {
            if msg.received == nil {
                msg.received = Date()
            }
            context.saveAndLogErrors()
            if messageUpdate.rfc822 {
                messageFetchedBlock?(msg)
            }
        } else {
            Logger.backendLogger.log(
                "We could not store the message. This can happen if the belonging account just has been deleted.")
            self.addError(BackgroundError.CoreDataError.couldNotStoreMessage(info: #function))
        }
    }

    func insertOrUpdate(pantomimeMessage: CWIMAPMessage, account: CdAccount) -> CdMessage? {
        return CdMessage.insertOrUpdate(pantomimeMessage: message,
                                        account: account,
                                        messageUpdate: messageUpdate)
    }
}
