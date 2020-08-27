//
//  Account.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 12/10/16.
//  Copyright © 2016 pEp Security S.A. All rights reserved.
//

import Foundation
import CoreData

public class Account: MessageModelObjectProtocol, ManagedObjectWrapperProtocol {

    // MARK: - ManagedObjectWrapperProtocol

    typealias T = CdAccount
    let moc: NSManagedObjectContext
    let cdObject: T

    required init(cdObject: T, context: NSManagedObjectContext) {
        self.cdObject = cdObject
        self.moc = context
    }

    func cdAccount() -> CdAccount {
        return cdObject
    }

    // MARK: - Life Cycle

    public init(user: Identity, servers: [Server], session: Session = Session.main) {

        let moc = session.moc
        let existingOrNewCdAccount = CdAccount.searchAccount(withAddress: user.address,
                                              context: moc) ?? CdAccount(context: moc)
        // Assure isMySelf is set //???: why?
        existingOrNewCdAccount.identity = Identity(identity: user).cdObject
        for server in servers {
            existingOrNewCdAccount.addToServers(server.cdObject)
        }

        self.cdObject = existingOrNewCdAccount
        self.moc = moc
    }

    //!!!: assume account verification/settings are the only ones using this. Should be obsolete after account verification is renewed.
    public convenience init(withDataFrom account: Account) {
        var servers = [Server]()
        account.servers?.forEach({ (server) in
            servers.append(Server(withDataFrom: server)) //!!!: creates servers, ends up having 1 acocunt (due to updateOrCreat) with 4 servers (2imap, 2smtp)
        })
        self.init(user: account.user, servers: servers)
    }
    
    // MARK: - Forwarded Getter & Setter

    public var user: Identity {
        get {
            // Using "!" because `parent` is NOT optional in MOM.
            return MessageModelObjectUtils.getIdentity(fromCdIdentity: cdObject.identity!)
        }
        set {
             cdObject.identity = newValue.cdObject//!!!: rename in MOM after NS move
        }
    }

    public var rootFolders: [Folder] {
        let cdAccount = cdObject
        var cdFolders = cdAccount.folders?.array as? [CdFolder] ?? []
        cdFolders = cdFolders.filter { $0.parent == nil && !$0.folderType.neverShowToUser }
        let folders: [Folder] = cdFolders.compactMap {
            guard let moc = $0.managedObjectContext else {
                Log.shared.errorAndCrash("No MOC")
                return nil
            }
            return Folder(cdObject: $0, context: moc)
        }
        return folders
    }

    // MARK: - Servers

    public var servers: UnappendableArray<Server>? {
        get {
            let cdRelationshipObjects = cdObject.servers?.allObjects as? [CdServer] ?? []
            let relationshipObjects = cdRelationshipObjects.map {
                Server(cdObject: $0, context: moc)
            }
            return UnappendableArray<Server>(array: relationshipObjects)
        }
    }

    public func replaceServers(with elements: [Server]) {
        cdObject.servers = nil
        appendToServers(elements)
    }

    public func appendToServers(_ element: Server) {
        appendToServers([element])
    }

    public func appendToServers(_ elements: [Server]) {
        let result = (cdObject.servers?.mutableCopy() as? NSMutableSet) ?? NSMutableSet()
        for element in elements {
            let cdElement = element.cdObject
            result.add(cdElement)
            element.cdObject.account = self.cdObject
        }
        cdObject.servers = result
    }

    public func removeFromServers(_ element: Server) {
        let result = (cdObject.servers?.mutableCopy() as? NSMutableSet) ?? NSMutableSet()
        result.remove(element.cdObject)
        element.moc.delete(element.cdObject)
        cdObject.servers = result
    }

    public var imapServer: Server? {
        get {
            return server(with: .imap)
        }
    }

    public var smtpServer: Server? {
        get {
            return server(with: .smtp)
        }
    }

    /**
     - Returns: The first root folder with `folderType` `.inbox`.
     */
    public func inbox() -> Folder? {
        return firstFolder(ofType: .inbox)
    }

    public func totalFolders() -> Int {
        let cdAccount = cdObject
        return cdAccount.folders?.count ?? 0
    }

    public var isIncludedInUnifiedFolders: Bool {
        get {
            return cdObject.includeFoldersInUnifiedFolders
        }
        set {
            cdObject.includeFoldersInUnifiedFolders = newValue
        }
    }
}

extension Account {

    private func server(with type: Server.ServerType) -> Server? {
        guard let cdServer = cdObject.server(type: type) else {
            return nil
        }
        return Server(cdObject: cdServer, context: moc)
    }
}

// - MARK: Count

extension Account {

    public static func countAllForUnified() -> Int {
        let isInUnifiedPredicate = CdAccount.PredicateFactory.isInUnified()
        return CdAccount.count(predicate: isInUnifiedPredicate)
    }
}

extension Account: Equatable {
    public static func ==(lhs: Account, rhs: Account) -> Bool {
        return lhs.user.hashValue == rhs.user.hashValue
    }
}

extension Account: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(user)
    }
}
