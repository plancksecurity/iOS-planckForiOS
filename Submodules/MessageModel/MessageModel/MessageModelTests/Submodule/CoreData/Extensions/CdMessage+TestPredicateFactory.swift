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

    static func by(uuid: MessageID,
                   folderName: String,
                   account: CdAccount,
                   includingDeleted: Bool = true,
                   context: NSManagedObjectContext) -> CdMessage? {
        let p = NSPredicate(format: "uuid = %@ and parent.name = %@ AND parent.account = %@",
                            uuid, folderName, account)
        guard
            let messages = CdMessage.all(predicate: p,
                                         in: context) as? [CdMessage]
            else {
                return nil
        }
        var found = messages
        if !includingDeleted {
            found = found.filter { $0.imapFields(context: context).imapFlags().deleted == false }
        }

        if found.count > 1 {
            //filter fake msgs
            found = found.filter { $0.uid != -1 }
            if found.count > 1 {
                let failureMessage = String(format: "multiple messages with UUID %@ in folder %@. Messages: %@",
                                            uuid,
                                            folderName,
                                            found)
                assertionFailure(failureMessage)
            }
        }
        return found.first
    }
}
