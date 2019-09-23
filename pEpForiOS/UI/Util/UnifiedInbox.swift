//
//  UnifiedInbox.swift
//
//  Created by Andreas Buff on 03.10.17.
//  Copyright © 2017 pEp Security S.A. All rights reserved.
//

import pEpIOSToolbox
import MessageModel

public class UnifiedInbox: VirtualFolderProtocol {

    private lazy var fetchMessagesService = FetchMessagesService()
    private lazy var fetchOlderMessagesService = FetchOlderImapMessagesService()
    static public let defaultUnifiedInboxName = "Unified Inbox"

    public var agregatedFolderType: FolderType? {
        return FolderType.inbox
    }

    public func fetchOlder(completion: (()->())? = nil) {
        guard let folderType = agregatedFolderType else {
            Log.shared.errorAndCrash(message: "missing folder type for unified inbox?")
            return
        }
        let folders = Folder.getAll(folderType: folderType)
        do {
            try fetchOlderMessagesService.runService(inFolders:folders) {
                completion?()
            }
        } catch {
            guard let er = error as? FetchServiceBaseClass.FetchError,
                er != FetchServiceBaseClass.FetchError.isFetching else {
                    Log.shared.errorAndCrash("Unexpected error")
                    return
            }
            // Alredy fetching do nothing
        }
    }

    public func fetchNewMessages(completion: (()->())? = nil) {
        guard let folderType = agregatedFolderType else {
            Log.shared.errorAndCrash(message: "missing folder type for unified inbox?")
            return
        }
        let folders = Folder.getAll(folderType: folderType)
        do {
            try fetchMessagesService.runService(inFolders:folders) {
                completion?()
            }
        } catch {
            guard let er = error as? FetchServiceBaseClass.FetchError,
                er != FetchServiceBaseClass.FetchError.isFetching else {
                    Log.shared.errorAndCrash("Unexpected error")
                    return
            }
            // Alredy fetching do nothing
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
            predicates.append(CdMessage.PredicateFactory.processed())
            predicates.append(Message.PredicateFactory.isNotAutoConsumable())
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
