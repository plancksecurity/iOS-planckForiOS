//
//  UnifiedInbox.swift
//
//  Created by Andreas Buff on 03.10.17.
//  Copyright © 2017 pEp Security S.A. All rights reserved.
//

import pEpIOSToolbox
import MessageModel


public class UnifiedInbox : UnifiedFolderBase {
    public override var agregatedFolderType: FolderType? {
        return FolderType.inbox
    }
    public override var name: String {
        return UnifiedInbox.defaultUnifiedInboxName
    }
}

public class UnifiedDraft : UnifiedFolderBase {
    public override var agregatedFolderType: FolderType? {
        return FolderType.drafts
    }
    public override var name: String {
        return NSLocalizedString("Drafts", comment: "Unified Drafts Folder title")
    }
}

public class UnifiedSent : UnifiedFolderBase {
    public override var agregatedFolderType: FolderType? {
        return FolderType.sent
    }
    public override var name: String {
        return NSLocalizedString("Sents", comment: "Unified Sent Folder title")
    }
}

public class UnifiedTrash : UnifiedFolderBase {
    public override var agregatedFolderType: FolderType? {
        return FolderType.trash
    }
    public override var name: String {
        return NSLocalizedString("Trashes", comment: "Unified Trash Folder title")
    }
}

public class UnifiedFolderBase: VirtualFolderProtocol {

    private lazy var fetchMessagesService = FetchMessagesService()
    private lazy var fetchOlderMessagesService = FetchOlderImapMessagesService()
    static public let defaultUnifiedInboxName = "Unified Inbox"

    public var agregatedFolderType: FolderType? {
        Log.shared.errorAndCrash("You MUST override this")
        return .none
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
        } catch FetchServiceBaseClass.FetchError.isFetching {
            // Already fetching do nothing
        } catch {
            // Unexpected error
            Log.shared.errorAndCrash(error: error)
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
            // Already fetching do nothing
        }
    }

    public var title: String {
        get {
            guard let type = agregatedFolderType else {
                Log.shared.errorAndCrash("Folder Type not found")
                return ""
            }
            return Folder.localizedName(realName: name, type: type)
        }
    }

    public var messagesPredicate: NSPredicate {
        get {
            var predicates = [NSPredicate]()
            guard let folderType = agregatedFolderType else {
                Log.shared.errorAndCrash("Folder Type not found")
                return NSPredicate()
            }
            predicates.append(Message.PredicateFactory.isIn(folderOfType: folderType))
            predicates.append(Message.PredicateFactory.existingMessages())
            predicates.append(Message.PredicateFactory.processed())
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
        Log.shared.errorAndCrash("You MUST override this")
        return ""
    }

    public var countUnread : Int {
        guard let folderType = agregatedFolderType else {
            Log.shared.errorAndCrash("Folder Type not found")
            return 0
        }
        return Folder.countUnreadIn(foldersOfType: folderType)
    }
}

extension UnifiedFolderBase: Equatable {
    public static func == (lhs: UnifiedFolderBase, rhs: UnifiedFolderBase) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}

extension UnifiedFolderBase: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(messagesPredicate.description)
    }
}
