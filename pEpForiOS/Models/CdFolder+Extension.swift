//
//  CdFolder+Extension.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 17/10/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import CoreData

import MessageModel

public extension CdFolder {
    @nonobjc static let comp = "CdFolder"

    /**
     If the folder has been deleted, undelete it.
     -Returns: True if the folder was actually flagged for deletion.
     */
    public static func reactivate(folder: CdFolder) -> Bool {
        let hasBeenDeleted = folder.shouldDelete
        folder.shouldDelete = false
        return hasBeenDeleted
    }

    public static func by(folderType: FolderType, account: CdAccount,
                          context: NSManagedObjectContext? = nil) -> CdFolder? {
        return CdFolder.first(attributes: ["folderTypeRawValue": folderType.rawValue, "account": account],
                              in: context)
    }

    public static func by(
        name: String, account: CdAccount,
        context: NSManagedObjectContext? = nil) -> CdFolder? {
        if name.lowercased() == ImapSync.defaultImapInboxName.lowercased() {
            return CdFolder.by(folderType: .inbox, account: account, context: context)
        }
        return CdFolder.first(attributes: ["name": name, "account": account])
    }

    /**
     - Returns: An optional tuple consisting of a `CdFolder`, and a flag indicating
     that this folder is new. The Inbox will never be returned as new.
     */
    public static func insertOrUpdate(folderName: String,
                                      folderSeparator: String?,
                                      folderType: FolderType?,
                                      selectable: Bool = true,
                                      account: CdAccount) -> (CdFolder, Bool)? {
        guard let moc = account.managedObjectContext else {
            Log.shared.errorAndCrash(component: #function,
                                     errorString: "ManagedObject without context.")
            return nil
        }
        var result: (CdFolder, Bool)?
        moc.performAndWait {
            // Treat Inbox specially, since its name is case insensitive.
            // For all other folders, it's undefined if they have to be handled
            // case insensitive or not, so no special handling for those.
            if folderName.lowercased() == ImapSync.defaultImapInboxName.lowercased() {
                if let folder = by(folderType: .inbox, account: account, context: moc) {
                    let _ = reactivate(folder: folder)
                    result = (folder, false)
                    return
                }
            }
            
            // Reactivate if previously deleted
            if let folder = by(name: folderName, account: account, context: moc) {
                if let type = folderType {
                    folder.folderType = type
                }
                folder.selectable = selectable
                result = (folder, reactivate(folder: folder))
                return
            }
            
            if let separator = folderSeparator {
                // Create folder hierarchy if necessary
                var pathsSoFar = [String]()
                var parentFolder: CdFolder? = nil
                let paths = folderName.components(separatedBy: separator)
                for p in paths {
                    pathsSoFar.append(p)
                    let pathName = (pathsSoFar as NSArray).componentsJoined(
                        by: separator)
                    let folder = insert(folderName: pathName, folderType: nil, account: account,
                                        context: moc)
                    //if it is the actual folder (has no child folder), set its folder type
                    if p == paths.last {
                        if let type = folderType {
                            folder.folderType = type
                        }
                        folder.selectable = selectable
                    }
                    // This is a dirty workaround for IOS-941.
                    if parentFolder != nil {
                        // Avoid crashes when using a folder that belongs to an account the
                        // user just deleted.
                        guard parentFolder?.managedObjectContext != nil else {
                            return
                        }
                    }
                    folder.parent = parentFolder
                    let scalars = separator.unicodeScalars
                    if let first = scalars.first {
                        folder.folderSeparator = Int16(first.value)
                    }
                    parentFolder = folder
                }
                if let createdFolder = parentFolder {
                    result = (createdFolder, true)
                    return
                } else {
                    result = nil
                    return
                }
            } else {
                // Just create the folder as-is, can't check for hierarchy
                let folder = insert(folderName: folderName,
                                    folderType: folderType,
                                    account: account,
                                    context: moc)
                result = (folder, true)
                return
            }
        }
        return result
    }

    static private func insert(
        folderName: String, folderType: FolderType?, account: CdAccount,
        context: NSManagedObjectContext) -> CdFolder {
        Log.verbose(component: comp, content: "insert \(folderName)")

        // Reactivate if previously deleted
        if let folder = by(name: folderName, account: account, context: context) {
            if let type = folderType {
                folder.folderType = type
            }
            let _ = reactivate(folder: folder)
            return folder
        }

        let folder = CdFolder.create(context: context)
        folder.name = folderName
        folder.account = account
        folder.uuid = MessageID.generate()
        if let type = folderType {
            folder.folderType = type
        }

        if folder.folderType != FolderType.normal || folderType != nil {
            // The folder has already a non-normal folder type set 
            // OR the folderType to use is explicitly given.
            // No need to do heuristics by folder name to find its purpose.
            return folder
        }

        if folderName.uppercased() == ImapSync.defaultImapInboxName.uppercased() {
            folder.folderType = FolderType.inbox
        } else {
            var foundMatch = false
            for ty in FolderType.allValuesToCheckFromServer {
                for theName in ty.folderNames() {
                    if folderName.matchesPattern("\(theName)",
                        reOptions: [.caseInsensitive]) {
                        foundMatch = true
                        folder.folderType = ty
                        break
                    }
                }
                if foundMatch {
                    break
                }
            }
            if !foundMatch {
                folder.folderType = FolderType.normal
            }
        }

        Log.verbose(component: comp, content: "insert \(folderName): \(folder.folderType)")
        return folder
    }

    /**
     - Returns: The predicate (for CdMessage) to get all (undeleted, valid)
     messages contained in that folder.
     */
    public func allMessagesPredicate() -> NSPredicate {
        let p1 = allMessagesIncludingDeletedPredicate()
        let p2 = NSPredicate(format: "imap.localFlags.flagDeleted = false")
        return NSCompoundPredicate(andPredicateWithSubpredicates: [p1, p2])
    }

    /**
     - Returns: The predicate (for CdMessage) to get all messages contained in that folder,
     even the deleted ones, so we don't fetch them again from the server.
     */
    public func allMessagesIncludingDeletedPredicate() -> NSPredicate {
        return NSPredicate(format: "parent = %@", self)
    }

    /**
     - Returns: All (undeleted, valid) messages in that folder.
     */
    public func allMessages() -> [CdMessage] {
        if let msgs = CdMessage.all(predicate: allMessagesPredicate()) as? [CdMessage] {
            return msgs
        }
        return []
    }

    public func firstUID() -> UInt {
        if let msg = CdMessage.first(
            predicate: allMessagesIncludingDeletedPredicate(),
            orderedBy: [NSSortDescriptor(key: "uid", ascending: true)]) {
            return UInt(msg.uid)
        }
        return 0
    }

    public func lastUID() -> UInt {
        if let msg = CdMessage.first(
            predicate: allMessagesIncludingDeletedPredicate(),
            orderedBy: [NSSortDescriptor(key: "uid", ascending: false)]) {
            return UInt(msg.uid)
        }
        return 0
    }
}
