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
                          context: NSManagedObjectContext = Record.Context.default) -> CdFolder? {
        return CdFolder.first(attributes: ["folderType": folderType.rawValue, "account": account],
                              in: context)
    }

    public static func by(
        name: String, account: CdAccount,
        context: NSManagedObjectContext = Record.Context.default) -> CdFolder? {
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
                                      account: CdAccount) -> (CdFolder, Bool)? {
        // Treat Inbox specially, since its name is case insensitive.
        // For all other folders, it's undefined if they have to be handled
        // case insensitive or not, so no special handling for those.
        if folderName.lowercased() == ImapSync.defaultImapInboxName.lowercased() {
            if let folder = by(folderType: .inbox, account: account) {
                let _ = reactivate(folder: folder)
                return (folder, false)
            }
        }

        // Reactivate if previously deleted
        if let folder = by(name: folderName, account: account) {
            if let type = folderType {
                folder.folderType = type.rawValue
            }
            return (folder, reactivate(folder: folder))
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
                let folder = insert(folderName: pathName, folderType: nil, account: account) //BUFF: check type here
                folder.parent = parentFolder
                let scalars = separator.unicodeScalars
                if let first = scalars.first {
                    folder.folderSeparator = Int16(first.value)
                }
                if let pf = parentFolder {
                    folder.parent = pf
                }
                parentFolder = folder
            }
            if let createdFolder = parentFolder {
                return (createdFolder, true)
            } else {
                return nil
            }
        } else {
            // Just create the folder as-is, can't check for hierarchy
            let folder = insert(folderName: folderName, folderType: folderType, account: account)
            return (folder, true)
        }
    }


    /// Set the given folder type. 
    /// Also searches for existing folder with give type and resets it to FolderType.normal to avoid having 
    /// two or more folders assigned to one type".
    ///
    /// - Parameter folderType: type to set
    func setFolderType(folderType: FolderType?) {
        guard let type = folderType else {
            return
        }

        if type == .normal {
            self.folderType = type.rawValue
            return
        }

        /*
         The given type represents a special folder (Drafts, Sent, != Normal).
         As only one folder must present one special purpose type, we have to assure uniqueness.
         */
        if let tmpAccount = self.account,
            let exsistingFolderForType = CdFolder.by(folderType: type, account: tmpAccount) {
            // A folder for the given purpose/type already exists. 
            // Reset the type of the existing one
            exsistingFolderForType.folderType = FolderType.normal.rawValue
        }
        self.folderType = type.rawValue
    }

    static func insert(folderName: String, folderType: FolderType?, account: CdAccount) -> CdFolder {
        Log.verbose(component: comp, content: "insert \(folderName)")

        // Reactivate if previously deleted
        if let folder = by(name: folderName, account: account) {
//            if let type = folderType {
//
////                folder.folderType = type.rawValue //BUFF: search for .folderType
//             }
            folder.setFolderType(folderType: folderType)
            let _ = reactivate(folder: folder)
            return folder
        }

        let folder = CdFolder.create()
        folder.name = folderName
        folder.account = account
        folder.uuid = MessageID.generate()
        folder.setFolderType(folderType: folderType)

        if folder.folderType != FolderType.normal.rawValue {
            // The folder has already a non-normal folder type set. 
            // No need to do heuristics by folder name to find its purpose.
            return folder
        }


        if folderName.uppercased() == ImapSync.defaultImapInboxName.uppercased() {
            folder.setFolderType(folderType: FolderType.inbox)
        } else {
            var foundMatch = false
            for ty in FolderType.allValuesToCheckFromServer {
                for theName in ty.folderNames() {
                    if folderName.matchesPattern("\(theName)",
                        reOptions: [.caseInsensitive]) {
                        foundMatch = true
                        folder.setFolderType(folderType: ty)
                        break
                    }
                }
                if foundMatch {
                    break
                }
            }
            if !foundMatch {
                folder.setFolderType(folderType: FolderType.normal)
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
        if let msgs = CdMessage.all(predicate: allMessagesPredicate()) {
            return msgs as! [CdMessage]
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
