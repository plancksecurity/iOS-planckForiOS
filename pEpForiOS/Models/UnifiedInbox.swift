//
//  UnifiedInbox.swift
//
//  Created by Andreas Buff on 03.10.17.
//  Copyright © 2017 pEp Security S.A. All rights reserved.
//

import MessageModel
import pEpIOSToolbox
import CoreData

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

    //!!!: This is wrong! It creates a CdFolder!
    public init() {
        super.init(
            name: UnifiedInbox.defaultUnifiedInboxName,
            parent: nil,
            uuid: "UnifiedInbox",
            account: UnifiedInbox.fakeAccount(),
            folderType: .inbox)
        resetFilter()
    }

    required init(cdObject: CdFolder, context: NSManagedObjectContext) {
        fatalError("init(cdObject:context:) has not been implemented. Actually MUST NOT be in UnifiedInbox")
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

    override public var realName: String {
        return name
    }

    override public func resetFilter() {
        let cf = CompositeFilter<FilterBase>()
        cf.add(filter: UnifiedFilter())
        filter = cf
    }

    override open func allCdMessages(includingDeleted: Bool = false,
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

        var result = !message.imapFlags.deleted && message.parent.folderType == .inbox
        if !markedForMoveToFolderAreContained {
            result =
                result && (message.targetFolder == nil || message.targetFolder == message.parent)
        }

        return result
    }
}
