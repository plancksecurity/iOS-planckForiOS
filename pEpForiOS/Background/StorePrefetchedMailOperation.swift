//
//  StorePrefetchedMailOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 15/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation
import CoreData

/**
 This can be used in a queue, or directly called with ```start()```.
 */
open class StorePrefetchedMailOperation: BaseOperation {
    let comp = "StorePrefetchedMailOperation"
    let coreDataUtil: ICoreDataUtil
    let message: CWIMAPMessage
    let accountEmail: String
    let quick: Bool

    /**
     - parameter quick: Store only the most important properties (for true), or do it completely,
     including attachments?
     */
    public init(coreDataUtil: ICoreDataUtil, accountEmail: String, message: CWIMAPMessage,
                quick: Bool = true) {
        self.coreDataUtil = coreDataUtil
        self.accountEmail = accountEmail
        self.message = message
        self.quick = quick
        super.init()
    }

    override open func main() {
        let privateMOC = coreDataUtil.privateContext()
        privateMOC.performAndWait({
            let model = CdModel.init(context: privateMOC)
            var result: Message? = nil
            if self.quick {
                (result, _) = model.quickInsertOrUpdatePantomimeMail(
                    self.message, accountEmail: self.accountEmail)
            } else {
                result = model.insertOrUpdatePantomimeMail(
                    self.message, accountEmail: self.accountEmail)
            }
            if result != nil {
                model.save()
            } else {
                self.errors.append(Constants.errorCannotStoreMail(self.comp))
            }
        })
    }
}
