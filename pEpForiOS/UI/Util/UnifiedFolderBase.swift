//
//  UnifiedInbox.swift
//
//  Created by Andreas Buff on 03.10.17.
//  Copyright © 2017 pEp Security S.A. All rights reserved.
//

import pEpIOSToolbox
import MessageModel

// MARK: - Unified Folder Base

public class UnifiedFolderBase: VirtualFolderProtocol {

    private lazy var fetchMessagesService = FetchMessagesService()
    private lazy var fetchOlderMessagesService = FetchOlderImapMessagesService()

    public var agregatedFolderType: FolderType? {
        Log.shared.errorAndCrash("You MUST override this")
        return .none
    }

    public var title: String {
        get {
            return Folder.localizedName(realName: name)
        }
    }

    public var name: String {
        Log.shared.errorAndCrash("You MUST override this")
        return ""
    }

    public var defaultFilter: MessageQueryResultsFilter {
        get {
            return MessageQueryResultsFilter(mustBeUnread: true, accounts: Account.all())
        }
    }

    public var countUnread : Int {
        guard let folderType = agregatedFolderType else {
            Log.shared.errorAndCrash("Folder Type not found")
            return 0
        }
        return Folder.countUnreadIn(foldersOfType: folderType, isUnified: true)
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

    /// Update LastLookAt property for all folders of the current type that are have the includeInUnifiedFolder on.
    public func updateLastLookAt() {
        guard let folderType = agregatedFolderType else {
            Log.shared.errorAndCrash(message: "missing folder type for unified inbox?")
            return
        }
        Folder.getAll(folderType: folderType).filter({$0.account.isIncludedInUnifiedFolders}).forEach({$0.updateLastLookAt()})
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
