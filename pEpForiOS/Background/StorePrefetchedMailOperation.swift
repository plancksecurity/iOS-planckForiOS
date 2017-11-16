//
//  StorePrefetchedMailOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 15/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import CoreData

import MessageModel

/**
 This can be used in a queue, or directly called with ```start()```.
 */
public class StorePrefetchedMailOperation: ConcurrentBaseOperation {
    enum OperationError: Error, LocalizedError {
        case cannotFindAccount
        case cannotStoreMessage
        case messageForFlagUpdateNotFound
    }

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
        let selfInfo = "\(unsafeBitCast(self, to: UnsafeRawPointer.self))"
        let theComp = comp
        let canceled = "\(self.isCancelled ? "" : "not") canceled"

        Log.shared.info(
            component: theComp,
            content: "\(selfInfo) \(canceled)")

        if !isCancelled {
            let privateMOC = Record.Context.background
            privateMOC.perform() { [weak self] in
                if let theSelf = self {
                    if !theSelf.isCancelled {
                        theSelf.storeMessage(context: privateMOC)
                        Log.shared.info(
                            component: theComp,
                            content: "\(selfInfo) stored: \(canceled)")
                    } else {
                        Log.shared.info(
                            component: theComp,
                            content: "\(selfInfo) not stored: \(canceled)")
                    }
                    theSelf.markAsFinished()
                } else {
                    Log.shared.info(
                        component: theComp,
                        content: "\(selfInfo) no self anymore, could not store")
                }
            }
        } else {
            markAsFinished()
        }
    }

    func storeMessage(context: NSManagedObjectContext) {
        guard let account = context.object(with: accountID) as? CdAccount else {
            addError(OperationError.cannotFindAccount)
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
            Log.shared.warn(component: #function,
                            content:
                """
We could not store the message. This can happen if the belonging account just has been deleted.
"""
            )
            self.addError(OperationError.cannotStoreMessage)
        }
    }

    func insertOrUpdate(pantomimeMessage: CWIMAPMessage, account: CdAccount) -> CdMessage? {
        return CdMessage.insertOrUpdate(
            pantomimeMessage: self.message, account: account, messageUpdate: messageUpdate)
    }
}
