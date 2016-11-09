//
//  StorePrefetchedMailOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 15/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation
import CoreData

import MessageModel

/**
 This can be used in a queue, or directly called with ```start()```.
 */
open class StorePrefetchedMailOperation: BaseOperation {
    let comp = "StorePrefetchedMailOperation"
    let message: CWIMAPMessage
    let connectInfo: EmailConnectInfo
    let quick: Bool

    /**
     - parameter quick: Store only the most important properties (for true), or do it completely,
     including attachments?
     */
    public init(connectInfo: EmailConnectInfo, message: CWIMAPMessage,
                quick: Bool = true) {
        self.connectInfo = connectInfo
        self.message = message
        self.quick = quick
        super.init()
    }

    override open func main() {
        let privateMOC = Record.Context.default
        privateMOC.performAndWait({
            self.storeMessage(context: privateMOC)
        })
    }

    func storeMessage(context: NSManagedObjectContext) {
        guard let account = context.object(with: connectInfo.accountObjectID)
            as? MessageModel.CdAccount else {
                Log.error(component: comp, errorString: "Cannot access account by object ID")
                return
        }
        let result = insert(pantomimeMessage: message, account: account, quick: quick)
        if result != nil {
            Record.save()
        } else {
            self.errors.append(Constants.errorCannotStoreMail(self.comp))
        }
    }

    func insert(pantomimeMessage: CWIMAPMessage, account: MessageModel.CdAccount,
                quick: Bool = true) -> MessageModel.CdMessage? {
        if quick {
            let (result, _) = CdMessagePantomime.quickInsertOrUpdate(
                pantomimeMessage: self.message, account: account)
            return result
        } else {
            return CdMessagePantomime.insertOrUpdate(
                pantomimeMessage: self.message, account: account)
        }
    }
}
