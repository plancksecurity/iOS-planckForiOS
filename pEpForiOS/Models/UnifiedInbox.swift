//
//  UnifiedInbox.swift
//
//  Created by Andreas Buff on 03.10.17.
//  Copyright © 2017 pEp Security S.A. All rights reserved.
//
import MessageModel

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
                Log.shared.errorAndCrash(component: #function, errorString: "No default account.")
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

    override open func allCdMessages(includingDeleted: Bool)  -> [CdMessage] {
        var predicates = [NSPredicate]()
        if let _ = filter {
            predicates.append(NSPredicate(format: "parent.folderTypeRawValue= %d",
                                          FolderType.inbox.rawValue))
        }
        return allCdMessages(includingDeleted: includingDeleted,
                             takingPredicatesIntoAccount: predicates)
    }

    override open func contains(message: Message, deletedMessagesAreContained: Bool = false) -> Bool {
        var result = false
        if let _ = filter{
            let parentF = message.parent

            if deletedMessagesAreContained {
                return parentF.folderType == .inbox
            }
            result = !message.isGhost && parentF.folderType == .inbox
        }
        return result
    }
}
