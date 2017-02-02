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
open class StorePrefetchedMailOperation: BaseOperation {
    static var someDict = [String:CWMessageUpdate]()

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

        if let mid = message.messageID() {
            if let oldUp = StorePrefetchedMailOperation.someDict[mid] {
                if oldUp.rfc822 && messageUpdate.rfc822 {
                    Log.warn(component: comp, content: "why double? \(mid)")
                }
            }
            StorePrefetchedMailOperation.someDict[mid] = messageUpdate
        }
    }

    override open func main() {
        if !isCancelled {
            let privateMOC = Record.Context.default
            privateMOC.performAndWait({
                if !self.isCancelled {
                    self.storeMessage(context: privateMOC)
                }
            })
        }
    }

    func storeMessage(context: NSManagedObjectContext) {
        guard let account = context.object(with: accountID)
            as? CdAccount else {
                addError(Constants.errorCannotFindAccount(component: comp))
                return
        }
        if let msg = insert(pantomimeMessage: message, account: account) {
            if msg.received == nil {
                msg.received = NSDate()
            }
            Record.saveAndWait(context: context)
            if messageUpdate.rfc822 {
                messageFetchedBlock?(msg)
            }
        } else {
            self.addError(Constants.errorCannotStoreMessage(self.comp))
        }
    }

    func insert(pantomimeMessage: CWIMAPMessage, account: CdAccount) -> CdMessage? {
        return CdMessage.insertOrUpdate(
            pantomimeMessage: self.message, account: account, messageUpdate: messageUpdate)
    }
}
