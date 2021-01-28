//
//  Folder+DisplaybleFolder.swift
//  MessageModel
//
//  Created by Xavier Algarra on 03/04/2019.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation
import pEpIOSToolbox

extension Folder: DisplayableFolderProtocol  {

    public func fetchNewMessages(completion: (()->())? = nil) {
        do {
            try fetchMessagesService.runService(inFolders: [self]) {
                completion?()
            }
        } catch FetchServiceBaseClass.FetchError.isFetching {
            // Already fetching ...
            // ... Do nothing.
        } catch {
            Log.shared.errorAndCrash("Unexpected error")
        }
    }

    public var isSelectable: Bool {
        return self.selectable
    }

    public func fetchOlder(completion: (()->())? = nil) {
        do {
            try fetchOlderService.runService(inFolders: [self])
        } catch FetchServiceBaseClass.FetchError.isFetching {
            // is already fetching, do nothing.
        } catch {
            Log.shared.errorAndCrash("Unexpected error")
        }
    }

    public var title: String {
        get {
            return self.realName
        }
    }

    public var messagesPredicate: NSPredicate {
        get {
            guard let safeCdFolder = cdFolder() else {
                Log.shared.errorAndCrash("folder without cdFolder is not possible sorry")
                return NSPredicate(value: false)
            }
            var predicates: [NSPredicate] = []

            predicates.append(CdMessage.PredicateFactory.belongingToParentFolder(parentFolder: safeCdFolder))
            if !folderType.isLocalFolder {
                predicates.append(CdMessage.PredicateFactory.existingMessages())
                predicates.append(CdMessage.PredicateFactory.processed())
            }
            predicates.append(CdMessage.PredicateFactory.isNotAutoConsumable())
            return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }
    }

    public var defaultFilter: MessageQueryResultsFilter {
        get {
            return MessageQueryResultsFilter(mustBeUnread: true, accounts: [account])
        }
    }
}
