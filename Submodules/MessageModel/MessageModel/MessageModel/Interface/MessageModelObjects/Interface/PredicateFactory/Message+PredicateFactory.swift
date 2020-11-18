//
//  Message+PredicateFactory.swift
//  MessageModel
//
//  Created by Andreas Buff on 25.09.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import CoreData

extension Message {

    public struct PredicateFactory {

        static public func isInInbox() -> NSPredicate {
            return CdMessage.PredicateFactory.isInInbox()
        }

        static public func existingMessages() -> NSPredicate {
            return CdMessage.PredicateFactory.existingMessages()
        }

        static public func processed() -> NSPredicate {
            return CdMessage.PredicateFactory.processed()
        }

        static public func unread(value : Bool) -> NSPredicate {
            return CdMessage.PredicateFactory.unread(value: value)
        }

        static public func isIn(folderOfType: FolderType) -> NSPredicate {
            return CdMessage.PredicateFactory.isIn(folderOfType: folderOfType)
        }
    }
}
