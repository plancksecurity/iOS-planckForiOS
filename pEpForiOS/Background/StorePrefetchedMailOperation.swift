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
 This can be used in a queue, or directly called with ```main()```.
 */
public class StorePrefetchedMailOperation: BaseOperation {
    let comp = "StorePrefetchedMailOperation"
    let message: CWIMAPMessage
    let accountEmail: String

    public init(grandOperator: IGrandOperator, accountEmail: String, message: CWIMAPMessage) {
        self.accountEmail = accountEmail
        self.message = message
        super.init(grandOperator: grandOperator)
    }

    override public func main() {
        let model = grandOperator.operationModel()
        if let mail = model.insertOrUpdatePantomimeMail(message, accountEmail: accountEmail) {
            model.save()
        } else {
            grandOperator.setErrorForOperation(self, error: Constants.errorCannotStoreMail(comp))
        }
    }
}