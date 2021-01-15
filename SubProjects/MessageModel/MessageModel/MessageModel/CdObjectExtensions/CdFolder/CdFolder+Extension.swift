//
//  CdFolder+Extension.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 17/10/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import CoreData

import pEpIOSToolbox

//!!!: looks OK, does not use non-CD Folder afaics. Sort to different files though (predicates, IMAP, all topics mixed here).
//!!!: check visibility!
extension CdFolder {
    @nonobjc static let comp = "CdFolder"

    public static func by(folderType: FolderType,
                          account: CdAccount,
                          context: NSManagedObjectContext? = nil) -> CdFolder? {
        return CdFolder.first(attributes: ["folderTypeRawValue": folderType.rawValue, "account": account],
                              in: context)
    }

    public static func by(name: String,
                          account: CdAccount,
                          context: NSManagedObjectContext? = nil) -> CdFolder? {
        if name.isInboxFolderName() {
            return CdFolder.by(folderType: .inbox, account: account, context: context)
        }
        return CdFolder.first(attributes: ["name": name, "account": account], in: context)
    }

    /**
     - Returns: The predicate (for CdMessage) to get all (undeleted, not marked to move to another folder, valid)
     messages contained in that folder.
     */
    public func allMessagesPredicate() -> NSPredicate {
        let p1 = allMessagesIncludingDeletedPredicate(fakeMessagesIncluded: true)
        let p2 = CdMessage.PredicateFactory.notImapFlagDeleted()
        let p3 = CdMessage.PredicateFactory.notMarkedForMoveToFolder()
        return NSCompoundPredicate(andPredicateWithSubpredicates: [p1, p2, p3])
    }

    /**
     - Returns: The predicate (for CdMessage) to get all messages contained in that folder,
     even the deleted ones, so we don't fetch them again from the server.
     */
    public func allMessagesIncludingDeletedPredicate(
        fakeMessagesIncluded: Bool = false) -> NSPredicate {

        let inParentFolder = NSPredicate(format: "%K = %@", CdMessage.RelationshipName.parent, self)
        var p = [inParentFolder]
        if !fakeMessagesIncluded {
            let isNotFakeMessage = CdMessage.PredicateFactory.isNotFakeMessage()
            p.append(isNotFakeMessage)
        }

        return NSCompoundPredicate(andPredicateWithSubpredicates: p)
    }

    /**
     - Returns: All (undeleted, valid) messages in that folder.
     */
    public func allMessages(context: NSManagedObjectContext) -> [CdMessage] {
        if let msgs = CdMessage.all(predicate: allMessagesPredicate(), in: context) as? [CdMessage] {
            return msgs
        }
        return []
    }

    func allMessagesExistingOnServer() -> NSPredicate {
        let p1 = allMessagesIncludingDeletedPredicate()
        let p2 = NSPredicate(format: "%K != %d",
                             CdMessage.AttributeName.uid,
                             CdMessage.uidNeedsAppend)
        return NSCompoundPredicate(andPredicateWithSubpredicates: [p1, p2])
    }

    func firstUID(context: NSManagedObjectContext) -> UInt {
        if let msg = CdMessage.first(predicate: allMessagesExistingOnServer(),
                                     orderedBy: [NSSortDescriptor(key: "uid", ascending: true)],
                                     in: context) {
            return UInt(msg.uid)
        }
        return 0
    }

    func lastUID(context: NSManagedObjectContext) -> UInt {
        if let msg = CdMessage.first(predicate: allMessagesExistingOnServer(),
                                     orderedBy: [NSSortDescriptor(key: "uid", ascending: false)],
                                     in: context) {
            return UInt(msg.uid)
        }
        return 0
    }
}

//!!!: from CdFolder.swift file. Re-read, maybe cleanup and/or move.

//!!!: move to own file
extension CdFolder {
    public var folderType: FolderType {
        get {
            guard let type = FolderType(rawValue: self.folderTypeRawValue) else {
                Log.shared.errorAndCrash("No type?!")
                return FolderType.normal
            }
            return type
        }
        set {
            self.folderTypeRawValue = newValue.rawValue
        }
    }
}

extension CdFolder {

    ///!!!: test only. maybe move
    public static func countBy(predicate: NSPredicate, context: NSManagedObjectContext) -> Int {
        let objs = CdFolder.all(predicate: predicate, in: context)
        return objs?.count ?? 0
    }

    public func folder() -> Folder {
        let moc: NSManagedObjectContext = managedObjectContext ?? Stack.shared.mainContext
        return MessageModelObjectUtils.getFolder(fromCdObject: self, context: moc)
    }
}

//!!!: move?!
extension CdFolder {
    public static func folderSeparatorAsString(cdAccount: CdAccount) -> String? {
        for cdF in cdAccount.folders?.array as? [CdFolder] ?? [] {
            if let fs = cdF.folderSeparatorAsString() {
                return fs
            }
        }
        return nil
    }

    public func folderSeparatorAsString() -> String? {
        if folderSeparator == 0 {
            return nil
        }
        return UnicodeScalar(Int(folderSeparator))?.escaped(asASCII: false)
    }
}

extension CdFolder {
    public func message(byUID: UInt, context:  NSManagedObjectContext) -> CdMessage? {
        let p = NSPredicate(format: "parent = %@ and uid = %d", self, byUID)
        return CdMessage.first(predicate: p, in: context)
    }

    //!!!: obsolete (?)
//    public static func by(folderName: String,
//                          folderType: FolderType,
//                          cdAccount: CdAccount) -> CdFolder? {
//        //For IMAP the combination (name, account) assures uniqueness due to IMAPs folder
//        // hierarchy naming ("Inbox.Subfolder")
//        var predicates = [NSPredicate]()
//        predicates.append(NSPredicate(format: "name = %@", folderName))
//        predicates.append(NSPredicate(format: "account = %@", cdAccount))
//        predicates.append(NSPredicate(format: "folderTypeRawValue = %i", folderType.rawValue))
//        let compound = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
//
//        guard let results = CdFolder.all(predicate: compound) else {
//            return nil
//        }
//        if results.count > 1 {
//            Log.shared.errorAndCrash(component: #function,
//                                     errorString: "We found more than one folder where it hould be unique.")
//        }
//        return results.first as? CdFolder
//    }
}
