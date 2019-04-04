//
//  UnifiedInbox.swift
//
//  Created by Andreas Buff on 03.10.17.
//  Copyright © 2017 pEp Security S.A. All rights reserved.
//

import pEpIOSToolbox
import MessageModel

public class UnifiedInbox: VirtualFolderProtocol {

    public var selectable: Bool {
        return true
    }

    
    public func fetchFolder() {
        //missing get all the folders
    }

    public var title: String {
        get {
            return Folder.localizedName(realName: name)
        }
    }

    public var predicate: NSPredicate {
        get {
            return NSPredicate(value: false)
        }
    }

    public var defaultFilter: MessageQueryResultsFilter {
        get {
            return MessageQueryResultsFilter(accounts: Account.all())
        }
    }

    static public let defaultUnifiedInboxName = "Unified Inbox"

    public var name: String {
        return UnifiedInbox.defaultUnifiedInboxName
    }
}
