//
//  UnifiedInbox.swift
//
//  Created by Andreas Buff on 03.10.17.
//  Copyright © 2017 pEp Security S.A. All rights reserved.
//

import pEpIOSToolbox
import MessageModel

public class UnifiedInbox: VirtualFolderProtocol {
    static public let defaultUnifiedInboxName = "Unified Inbox"

    public var agregatedFolderType: FolderType? {
        return FolderType.inbox
    }

    public func fetchOlder() {
        for folder in Folder.getAll(folderType: .inbox) {
            folder.fetchOlder()
        }
    }

    public var title: String {
        get {
            return Folder.localizedName(realName: name)
        }
    }

    public var messagesPredicate: NSPredicate {
        get {
            var predicates = [NSPredicate]()
            predicates.append(CdMessage.PredicateFactory.isInInbox())
            predicates.append(CdMessage.PredicateFactory.existingMessages())
            return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }
    }

    public var defaultFilter: MessageQueryResultsFilter {
        get {
            return MessageQueryResultsFilter(mustBeUnread: true, accounts: Account.all())
        }
    }

    public var name: String {
        return UnifiedInbox.defaultUnifiedInboxName
    }
}
