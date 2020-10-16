//
//  CdMessage+TestPredicateFactory.swift
//  pEpForiOSTests
//
//  Created by Adam Kowalski on 21/05/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel
import CoreData
import pEpIOSToolbox

extension CdMessage {

    static func by(uuid: MessageID,
                   account: CdAccount,
                   context: NSManagedObjectContext) -> [CdMessage] {

        let cdMessage_parent_account = CdMessage.RelationshipName.parent + "." +
        CdFolder.RelationshipName.account

        return CdMessage.all(
            predicate: NSPredicate(format: "%K = %@ AND %K = %@",
                                   CdMessage.AttributeName.uuid,
                                   uuid,
                                   cdMessage_parent_account,
                                   account), in: context) as? [CdMessage] ?? []
    }

    static func by(uuid: MessageID,
                   uid: UInt,
                   account: CdAccount,
                   context: NSManagedObjectContext) -> CdMessage? {
        return CdMessage.first(predicate:
            NSPredicate(format: "uuid = %@ AND uid = %d AND parent.account.identity.address = %@",
                        uuid, uid, account.identity!.address!),
                               in: context)
    }

}
