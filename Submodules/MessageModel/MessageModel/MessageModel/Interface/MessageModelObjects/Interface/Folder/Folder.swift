//
//  Folder.swift
//  MailModel
//
//  Created by Dirk Zimmermann on 23/09/16.
//  Copyright © 2016 pEp Security S.A. All rights reserved.
//

import CoreData

public class Folder: MessageModelObjectProtocol, ManagedObjectWrapperProtocol {

    // MARK: - ManagedObjectWrapperProtocol

    typealias T = CdFolder
    let moc: NSManagedObjectContext
    let cdObject: T

    required init(cdObject: T, context: NSManagedObjectContext) {
        self.cdObject = cdObject
        self.moc = context
    }

    // MARK: - Forwarded Getter & Setter

    func cdFolder() -> CdFolder? {
        return cdObject
    }

    public struct ImapFlagsCriteria {
        /**
         If this is set to a value, consider only messages that have that flag.
         */
        let seen: Bool?

        /**
         If this is set to a value, consider only messages that have that flag.
         */
        let flagged: Bool?
    }

    lazy var fetchOlderService = FetchOlderImapMessagesService()
    lazy var fetchMessagesService = FetchMessagesService()
    
    public var parent: Folder?
    public var name: String {
        get {
            guard let result = cdObject.name else {
                Log.shared.errorAndCrash("Non-optional field missing value")
                return "--"
            }
            return result
        }
        set {
            cdObject.name = newValue
        }
    }
    // Indicates whether or not the IMAP \Noselect tag is set. Is also misused to mark folders that
    // are path components only (are nodes).
    public var selectable: Bool {
        get {
            return cdObject.selectable
        }
    }

    /// Is actually updateOrCreate. //!!!: needs love
    // Also must not be able to set isSelectected
    /// - note: session defaults to .main. The cliemt (YOU) is responsible for correct usage.
    init(name: String,
         parent: Folder?,
         uuid: MessageID = MessageID.generateUUID(),
         account: Account,
         folderType: FolderType,
         lastLookedAt: Date? = nil,
         selectable: Bool = false,
         session: Session = Session.main) {
        let moc = session.moc

        var existing: CdFolder? = nil
        if let cdAccount = moc.object(with: account.cdObject.objectID) as? CdAccount {
            existing = CdFolder.updateOrCreate(folderName: name,
                                               folderSeparator: nil,
                                               folderType: folderType,
                                               account: cdAccount,
                                               context: moc)
        }

        let createe = existing ?? CdFolder(context: moc)
        createe.name = name
        createe.account = account.cdAccount()
        createe.parent = parent?.cdFolder()
        createe.folderTypeRawValue = folderType.rawValue
        createe.lastLookedAt = lastLookedAt
        createe.selectable = selectable

        self.cdObject = createe
        self.moc = moc
    }
    
    public var realName: String {
        let completename = cdObject.name
        if let u = UnicodeScalar(Int(cdObject.folderSeparator)) {
            let seperatedName = completename?.components(separatedBy: String(describing: u))
            if let last = seperatedName?.last {
                return last
            }
        }
        return name
    }
    
    public var lastLookedAt: Date? {
        get {
            return cdObject.lastLookedAt
        }
        set {
            cdObject.lastLookedAt = newValue
        }
    }
    public var account: Account {
        get {
            return cdObject.account!.account()
        }
        set {
            cdObject.parent?.account = newValue.cdAccount()
        }
    }
    var folderUuids = MutableOrderedSet<MessageID>()
    var messageUuids = MutableOrderedSet<MessageID>()
    public var folderType: FolderType {
        return cdObject.folderType
    }

    public func subFolders () -> [Folder]{
        let cdSubFolders = cdObject.subFolders?.array as? [CdFolder] ?? []
        let cdDisplayableSubfolders = cdSubFolders.filter { !$0.folderType.neverShowToUser }
        return cdDisplayableSubfolders.map { return $0.folder() }
    }

    public func contains(message: Message, deletedMessagesAreContained: Bool = false,
                         markedForMoveToFolderAreContained: Bool = false) -> Bool {
        let cdFolder = cdObject
        var ps = [NSPredicate]()
        ps.append(CdFolder.PredicateFactory.containedMessages(cdFolder: cdFolder))
        if deletedMessagesAreContained {
            ps.append(NSPredicate(format: "uuid = %@", message.uuid))
            let account = message.parent.account.cdAccount()
            ps.append(NSPredicate(format: "parent.account = %@", account))
            ps.append(NSPredicate(format: RelationshipKeyPath.cdFolder_parent_account
                + " = %@", account))
        }
        if !markedForMoveToFolderAreContained {
            ps.append(CdMessage.PredicateFactory.notMarkedForMoveToFolder())
        }
        let p = NSCompoundPredicate(andPredicateWithSubpredicates: ps)
        let d = defaultSortDescriptors()
        if let _ = CdMessage.first(predicate: p, orderedBy: d, in: session.moc) {
            return true
        }
        return false
    }

    public static func by(account: Account, folderType: FolderType) -> Folder? {
        let cdAccount = account.cdObject
        guard var cdFolders = cdAccount.folders?.array as? [CdFolder] else {
            return nil
        }
        cdFolders = cdFolders.filter { $0.folderType == folderType }

        return cdFolders.first?.folder()
    }
}

// MARK: - Helper

extension Folder {

    //!!!: rm! DisplayableFolder.messagesPredicate should be the only place offering predicates.
    /// Helper for `allCdMessages` and `allCdMessagesCount`.
    private func preparePredicatesForAllCdMessages(
        includingDeleted: Bool,
        includingMarkedForMoveToFolder: Bool = false,
        ignoringPepRating: Bool = false,
        takingPredicatesIntoAccount prePredicates: [NSPredicate]) -> [NSPredicate] {
        var predicates = prePredicates

        if !folderType.isLocalFolder {
            predicates.append(CdMessage.PredicateFactory.notWaitingForImapAppend())
        }

        if !ignoringPepRating {
            predicates.append(CdMessage.PredicateFactory.decrypted())
        }
        if !includingDeleted {
            predicates.append(CdMessage.PredicateFactory.notImapFlagDeleted())
        }
        if !includingMarkedForMoveToFolder {
            predicates.append(CdMessage.PredicateFactory.notMarkedForMoveToFolder())
        }

        return predicates
    }

    /**
     Helper for `allCdMessages` and `allCdMessagesCount`.
     */
    private func preparePredicatesForAllCdMessages() -> [NSPredicate] {
        var predicates = [NSPredicate]()
        predicates.append(CdFolder.PredicateFactory.containedMessages(cdFolder: cdObject))

        return predicates
    }

    private func defaultSortDescriptors() -> [NSSortDescriptor] {
        return [NSSortDescriptor(key: "sent", ascending: false),
                NSSortDescriptor(key: "uid", ascending: false),
                NSSortDescriptor(key: "parent.name", ascending: false)]
    }

    //!!!: MUST NOT be public (returns CD)
    /// - Returns: All the messages contained in that folder.
    func allCdMessages(includingDeleted: Bool = false,
                       includingMarkedForMoveToFolder: Bool = false,
                       ignoringPepRating: Bool = false) -> [CdMessage] {
        let predicates = preparePredicatesForAllCdMessages()

        return allCdMessages(includingDeleted: includingDeleted,
                             includingMarkedForMoveToFolder: includingMarkedForMoveToFolder,
                             ignoringPepRating: ignoringPepRating,
                             takingPredicatesIntoAccount: predicates)
    }

    //!!!: should become obsolete with FRC
    private func allCdMessages(
        includingDeleted: Bool,
        includingMarkedForMoveToFolder: Bool = false,
        ignoringPepRating: Bool = false,
        takingPredicatesIntoAccount prePredicates: [NSPredicate])  -> [CdMessage] {
        let predicates = preparePredicatesForAllCdMessages(
            includingDeleted: includingDeleted,
            includingMarkedForMoveToFolder: includingMarkedForMoveToFolder,
            ignoringPepRating: ignoringPepRating,
            takingPredicatesIntoAccount: prePredicates)
        let p = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        let descs = defaultSortDescriptors()
        let msgs = CdMessage.all(predicate: p, orderedBy: descs, in: session.moc) as? [CdMessage] ?? []
        return msgs
    }
}

// MARK: - Custom{Debug}StringConvertible

extension Folder: CustomDebugStringConvertible {
    public var debugDescription: String {
        let parentName = parent?.name ?? "nil"
        return "<Folder name: \(name) parent: \(parentName)>"
    }
}

extension Folder: CustomStringConvertible {
    public var description: String {
        return debugDescription
    }
}

// MARK: - Hashable

extension Folder: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(account)
        hasher.combine(name)
    }
}

// MARK: - Equatable

extension Folder: Equatable {

    public static func ==(lhs: Folder, rhs: Folder) -> Bool {
        return lhs.account == rhs.account && lhs.name == rhs.name
    }
}
