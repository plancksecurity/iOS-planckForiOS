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
public class StorePrefetchedMailOperation: BaseOperation {
    let comp = "StorePrefetchedMailOperation"
    let message: CWIMAPMessage
    let accountEmail: String
    let quick: Bool

    /**
     - parameter quick: Store only the most important properties (for true), or do it completely,
     including attachments?
     */
    public init(grandOperator: IGrandOperator, accountEmail: String, message: CWIMAPMessage,
                quick: Bool = true) {
        self.accountEmail = accountEmail
        self.message = message
        self.quick = quick
        super.init(grandOperator: grandOperator)
    }

    override public func main() {
        let privateMOC = grandOperator.coreDataUtil.privateContext()
        privateMOC.performBlockAndWait({
            let model = Model.init(context: privateMOC)
            var result: IMessage? = nil
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
                self.grandOperator.setErrorForOperation(self,
                    error: Constants.errorCannotStoreMail(self.comp))
            }
        })
    }
}