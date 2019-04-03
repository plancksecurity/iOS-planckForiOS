//
//  UnifiedInbox.swift
//
//  Created by Andreas Buff on 03.10.17.
//  Copyright © 2017 pEp Security S.A. All rights reserved.
//

import pEpIOSToolbox
import MessageModel

public class UnifiedInbox: VirtualFolderProtocol {

    public var folderType: FolderType {
        get {
            return FolderType.inbox
        }
    }

    public var title: String {
        get {
            return "UnifiedInboxTitle"
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

    public var realName: String {
        return title
    }
//
//    public var folders: [Folder] {
//        return Folder.allFolders(ofType: .inbox)
//    }
//
//
//    public init() {
//        super.init(
//            name: UnifiedInbox.defaultUnifiedInboxName,
//            parent: nil,
//            uuid: "UnifiedInbox",
//            account: UnifiedInbox.fakeAccount(),
//            folderType: .inbox)
//        resetFilter()
//    }
//
//    private func fakeAccount() -> Account {
//        return UnifiedInbox.fakeAccount()
//    }
//
//    private static func fakeAccount() -> Account {
//        let fakeId = Identity(
//            address: "unifiedInbox@fake.address.com",
//            userID: nil,
//            userName: "fakeName",
//            isMySelf: true)
//        return Account(user: fakeId, servers: [Server]())
//    }
//
//    override open func save() {
//        // do nothing. Unified Inbox can not be saved
//    }
//
//    override public func resetFilter() {
//        let cf = CompositeFilter<FilterBase>()
//        cf.add(filter: UnifiedFilter())
//        filter = cf
//    }
//
//    override open func allCdMessagesNonThreaded(includingDeleted: Bool = false,
//                                                includingMarkedForMoveToFolder: Bool = false,
//                                                ignoringPepRating: Bool = false)
//        -> [CdMessage] {
//            return allCdMessages(includingDeleted: includingDeleted,
//                                 includingMarkedForMoveToFolder: includingMarkedForMoveToFolder,
//                                 ignoringPepRating: ignoringPepRating,
//                                 takingPredicatesIntoAccount: filter?.predicates ?? [])
//    }
//
//    override open func contains(message: Message,
//                                deletedMessagesAreContained: Bool = false,
//                                markedForMoveToFolderAreContained: Bool = false) -> Bool {
//        guard let theFilter = filter else {
//            return false
//        }
//
//        if deletedMessagesAreContained && markedForMoveToFolderAreContained {
//            return theFilter.fulfillsFilter(message: message)
//        }
//
//        var result = !(message.imapFlags?.deleted ?? false) && message.parent.folderType == .inbox
//        if !markedForMoveToFolderAreContained {
//            result =
//                result && (message.targetFolder == nil || message.targetFolder == message.parent)
//        }
//
//        return result
//    }
}
