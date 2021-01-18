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

    static func by(folderType: FolderType,
                          account: CdAccount,
                          context: NSManagedObjectContext? = nil) -> CdFolder? {
        return CdFolder.first(attributes: ["folderTypeRawValue": folderType.rawValue, "account": account],
                              in: context)
    }

    static func by(name: String,
                          account: CdAccount,
                          context: NSManagedObjectContext? = nil) -> CdFolder? {
        if name.isInboxFolderName() {
            return CdFolder.by(folderType: .inbox, account: account, context: context)
        }
        return CdFolder.first(attributes: ["name": name, "account": account], in: context)
    }

    /**
     - Returns: All (undeleted, valid) messages in that folder.
     */
    func allMessages(context: NSManagedObjectContext) -> [CdMessage] {
        let p = CdMessage.PredicateFactory.allMessages(parentFolder: self)
        if let msgs = CdMessage.all(predicate: p, in: context) as? [CdMessage] {
            return msgs
        }
        return []
    }

    func firstUID(context: NSManagedObjectContext) -> UInt {
        let p = CdMessage.PredicateFactory.allMessagesExistingOnServer(parentFolder: self)
        if let msg = CdMessage.first(predicate: p,
                                     orderedBy: [NSSortDescriptor(key: "uid", ascending: true)],
                                     in: context) {
            return UInt(msg.uid)
        }
        return 0
    }

    func lastUID(context: NSManagedObjectContext) -> UInt {
        let p = CdMessage.PredicateFactory.allMessagesExistingOnServer(parentFolder: self)
        if let msg = CdMessage.first(predicate: p,
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
    var folderType: FolderType {
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

    ///!!!: test only.Move!
    static func countBy(predicate: NSPredicate, context: NSManagedObjectContext) -> Int {
        let objs = CdFolder.all(predicate: predicate, in: context)
        return objs?.count ?? 0
    }

    func folder() -> Folder {
        let moc: NSManagedObjectContext = managedObjectContext ?? Stack.shared.mainContext
        return MessageModelObjectUtils.getFolder(fromCdObject: self, context: moc)
    }
}

//!!!: move?!
extension CdFolder {
    static func folderSeparatorAsString(cdAccount: CdAccount) -> String? {
        for cdF in cdAccount.folders?.array as? [CdFolder] ?? [] {
            if let fs = cdF.folderSeparatorAsString() {
                return fs
            }
        }
        return nil
    }

    func folderSeparatorAsString() -> String? {
        if folderSeparator == 0 {
            return nil
        }
        return UnicodeScalar(Int(folderSeparator))?.escaped(asASCII: false)
    }
}

extension CdFolder {
    func message(byUID: UInt, context: NSManagedObjectContext) -> CdMessage? {
        let p = CdMessage.PredicateFactory.parentFolder(self, uid: byUID)
        return CdMessage.first(predicate: p, in: context)
    }
}
