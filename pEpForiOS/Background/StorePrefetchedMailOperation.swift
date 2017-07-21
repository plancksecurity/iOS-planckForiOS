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
open class StorePrefetchedMailOperation: ConcurrentBaseOperation {
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
        accountID: NSManagedObjectID, message: CWIMAPMessage,
        messageUpdate: CWMessageUpdate, name: String? = nil,
        messageFetchedBlock: MessageFetchedBlock? = nil) {
        self.accountID = accountID
        self.message = message
        self.messageUpdate = messageUpdate
        self.messageFetchedBlock = messageFetchedBlock
        super.init(parentName: name)
    }

    override open func main() {
        let selfInfo = "\(unsafeBitCast(self, to: UnsafeRawPointer.self))"
        let theComp = comp
        let canceled = "\(self.isCancelled ? "" : "not") canceled"

        Log.shared.info(
            component: theComp,
            content: "\(selfInfo) \(canceled)")

        if !isCancelled {
            let privateMOC = Record.Context.default
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
        guard let account = context.object(with: accountID)
            as? CdAccount else {
                addError(OperationError.cannotFindAccount)
                return
        }
        if messageUpdate.isFlagsOnly() {
            guard
                let messageID = message.messageID(),
                let folderName = message.folder()?.name(),
                let cdMsg = CdMessage.by(uuid: messageID, folderName: folderName) else {
                    addError(OperationError.messageForFlagUpdateNotFound)
                    return
            }
            context.updateAndSave(object: cdMsg) {
                let _ = cdMsg.updateFromServer(cwFlags: message.flags())
            }
        } else if let msg = insert(pantomimeMessage: message, account: account) {
            if msg.received == nil {
                msg.received = NSDate()
            }
            context.saveAndLogErrors()
            if messageUpdate.rfc822 {
                messageFetchedBlock?(msg)
            }
        } else {
            self.addError(OperationError.cannotStoreMessage)
        }
    }

    func insert(pantomimeMessage: CWIMAPMessage, account: CdAccount) -> CdMessage? {
        return CdMessage.insertOrUpdate(
            pantomimeMessage: self.message, account: account, messageUpdate: messageUpdate)
    }
}
