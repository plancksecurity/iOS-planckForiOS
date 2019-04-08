//
//  UnifiedInbox.swift
//
//  Created by Andreas Buff on 03.10.17.
//  Copyright © 2017 pEp Security S.A. All rights reserved.
//

import pEpIOSToolbox

public class UnifiedInbox: Folder {
    static public let defaultUnifiedInboxName = "Unified Inbox"

    public var folders: [Folder] {
        return Folder.allFolders(ofType: .inbox)
    }

    override public var account: Account {
        set {
            super.account = newValue
        }
        get {
            guard let safeAccount = Account.defaultAccount() else {
                Logger.modelLogger.errorAndCrash("No default account")
                return fakeAccount()
            }
           return safeAccount
        }
    }

    public init() {
        super.init(
            name: UnifiedInbox.defaultUnifiedInboxName,
            parent: nil,
            uuid: "UnifiedInbox",
            account: UnifiedInbox.fakeAccount(),
            folderType: .inbox)
        resetFilter()
    }

    private func fakeAccount() -> Account {
        return UnifiedInbox.fakeAccount()
    }

    private static func fakeAccount() -> Account {
        let fakeId = Identity(
            address: "unifiedInbox@fake.address.com",
            userID: nil,
            userName: "fakeName",
            isMySelf: true)
        return Account(user: fakeId, servers: [Server]())
    }

    override open func save() {
        // do nothing. Unified Inbox can not be saved
    }

    override public var realName: String {
        return name
    }

    override public func resetFilter() {
        let cf = CompositeFilter<FilterBase>()
        cf.add(filter: UnifiedFilter())
        filter = cf
    }

    override open func allCdMessagesNonThreaded(includingDeleted: Bool = false,
                                                includingMarkedForMoveToFolder: Bool = false,
                                                ignoringPepRating: Bool = false)
        -> [CdMessage] {
            return allCdMessages(includingDeleted: includingDeleted,
                                 includingMarkedForMoveToFolder: includingMarkedForMoveToFolder,
                                 ignoringPepRating: ignoringPepRating,
                                 takingPredicatesIntoAccount: filter?.predicates ?? [])
    }

    override open func contains(message: Message,
                                deletedMessagesAreContained: Bool = false,
                                markedForMoveToFolderAreContained: Bool = false) -> Bool {
        guard let theFilter = filter else {
            return false
        }

        if deletedMessagesAreContained && markedForMoveToFolderAreContained {
            return theFilter.fulfillsFilter(message: message)
        }

        var result = !(message.imapFlags?.deleted ?? false) && message.parent.folderType == .inbox
        if !markedForMoveToFolderAreContained {
            result =
                result && (message.targetFolder == nil || message.targetFolder == message.parent)
        }

        return result
    }
}
