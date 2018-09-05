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
        predicates.append(NSPredicate(format: "bodyFetched = true"))//IOS-1274: rm body fetched field. We always fetch everything.
        predicates.append(undeleted())//IOS-1274: take targetfolder into account (FIXED)
        predicates.append(notMarkedForMoveToFolder())
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }

    static public func isInInbox() -> NSPredicate {
        return NSPredicate(format: "parent.folderTypeRawValue = %d", FolderType.inbox.rawValue)
    }
}
