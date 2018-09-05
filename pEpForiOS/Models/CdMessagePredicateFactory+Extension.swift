//
//  CdMessagePredicateFactory+Extension.swift
//  pEpForiOSTests
//
//  Created by Andreas Buff on 05.09.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel

/// Predicates MessageModel should not be aware of
extension CdMessage.PredicateFactory {

    static public func existingMessages() -> NSPredicate {
        var predicates = [NSPredicate]()
        predicates.append(NSPredicate(format: "bodyFetched = true"))
        predicates.append(notImapFlagDeleted())
        predicates.append(notMarkedForMoveToFolder())
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }

    static public func isInInbox() -> NSPredicate {
        return NSPredicate(format: "parent.folderTypeRawValue = %d", FolderType.inbox.rawValue)
    }
}
