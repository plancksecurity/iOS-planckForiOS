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
    let message: CWIMAPMessage
    let quick: Bool
    let accountID: NSManagedObjectID
    let messageFetchedBlock: MessageFetchedBlock?

    /**
     - parameter quick: Store only the most important properties (for true), or do it completely,
     including attachments?
     */
    public init(
        accountID: NSManagedObjectID, message: CWIMAPMessage,
        quick: Bool = true, name: String? = nil, messageFetchedBlock: MessageFetchedBlock? = nil) {
        self.accountID = accountID
        self.message = message
        self.quick = quick
        self.messageFetchedBlock = messageFetchedBlock
        super.init(parentName: name)
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
        let result = insert(pantomimeMessage: message, account: account, quick: quick)
        if let msg = result {
            if msg.received == nil {
                msg.received = NSDate()
            }
            Record.saveAndWait(context: context)
            if !quick {
                messageFetchedBlock?(msg)
            }
        } else {
            self.addError(Constants.errorCannotStoreMessage(self.comp))
        }
    }

    func insert(pantomimeMessage: CWIMAPMessage, account: CdAccount,
                quick: Bool = true) -> CdMessage? {
        if quick {
            let result = CdMessage.quickInsertOrUpdate(
                pantomimeMessage: self.message, account: account)
            return result
        } else {
            return CdMessage.insertOrUpdate(
                pantomimeMessage: self.message, account: account)
        }
    }
}
