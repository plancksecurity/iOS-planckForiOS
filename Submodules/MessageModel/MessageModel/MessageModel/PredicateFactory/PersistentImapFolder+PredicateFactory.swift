//
//  PersistentImapFolder+PredicateFactory.swift
//  MessageModel
//
//  Created by Adam Kowalski on 23/04/2020.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import Foundation
import CoreData

extension PersistentImapFolder {
    public struct PredicateFactory {
        static public func messageWithUid(uid:UInt) -> NSPredicate {
            return NSPredicate(format: "%K = %d", CdMessage.AttributeName.uid, uid)
        }
        static public func messageWithImapMessageNumber(messageNumber: UInt, folder: CdFolder) -> NSPredicate {
            return NSPredicate(format: "parent = %@ and imap.messageNumber = %d", folder, messageNumber)
        }
        static public func messagesWithGreaterThanMessageNumber(messageNumber: Int32, folder: CdFolder) -> NSPredicate {
            return NSPredicate(format: "%K = %@ and %K > %d",
                               CdMessage.RelationshipName.parent, folder,
                               RelationshipKeyPath.cdMessage_imap_messageNum, messageNumber)
        }
        static public func parentFolder(cdFolder:CdFolder) -> NSPredicate {
            return NSPredicate(format: "%K = %@", CdMessage.RelationshipName.parent, cdFolder)
        }
    }
}
