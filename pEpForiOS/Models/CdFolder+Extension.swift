//
//  CdFolder+Extension.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 17/10/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import MessageModel

public extension CdFolder {
    /**
     If the folder has been deleted, undelete it.
     */
    public static func reactivate(folder: CdFolder) -> CdFolder {
        folder.shouldDelete = false
        return folder
    }

    public static func by(folderType: FolderType, account: CdAccount) -> CdFolder? {
        return CdFolder.first(with: ["folderType": folderType.rawValue, "account": account])
    }

    public static func by(name: String, account: CdAccount) -> CdFolder? {
        return CdFolder.first(with: ["name": name, "account": account])
    }

    public static func insertOrUpdate(folderName: String, folderSeparator: String?,
                                      account: CdAccount) -> CdFolder? {
        // Treat Inbox specially, since its name is case insensitive.
        // For all other folders, it's undefined if they have to be handled
        // case insensitive or not, so no special handling for those.
        if folderName.lowercased() == ImapSync.defaultImapInboxName.lowercased() {
            if let folder = by(folderType: .inbox, account: account) {
                return reactivate(folder: folder)
            }
        }

        // Reactivate if previously deleted
        if let folder = by(name: folderName, account: account) {
            return reactivate(folder: folder)
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
                let folder = insert(folderName: pathName, account: account)
                folder.parent = parentFolder
                if let pf = parentFolder {
                    folder.parent = pf
                }
                parentFolder = folder
            }
            return parentFolder
        } else {
            // Just create the folder as-is, can't check for hierarchy
            let folder = insert(folderName: folderName, account: account)
            return folder
        }
    }

    static func insert(folderName name: String, account: CdAccount) -> CdFolder {
        // Reactivate if previously deleted
        if let folder = by(name: name, account: account) {
            return reactivate(folder: folder)
        }

        let folder = CdFolder.create(with: ["name": name, "account": account,
                                            "uuid": UUID.generate()])

        if name.uppercased() == ImapSync.defaultImapInboxName.uppercased() {
            folder.folderType = FolderType.inbox.rawValue
        } else {
            var foundMatch = false
            for ty in FolderType.allValuesToCheckFromServer {
                for theName in ty.folderNames() {
                    if name.matchesPattern("\(theName)",
                        reOptions: [.caseInsensitive]) {
                        foundMatch = true
                        folder.folderType = ty.rawValue
                        break
                    }
                }
                if foundMatch {
                    break
                }
            }
            if !foundMatch {
                folder.folderType = FolderType.normal.rawValue
            }
        }

        return folder
    }
    
    /**
     - Returns: The predicate (for CdMessage) to get all (undeleted, valid)
     messages contained in that folder.
     */
    public func allMessagesPredicate() -> NSPredicate {
        return NSPredicate(format: "parent = %@ and imap.flagDeleted = false", self)
    }

    /**
     - Returns: All (undeleted, valid) messages in that folder.
     */
    public func allMessages() -> [CdMessage] {
        if let msgs = CdMessage.all(with: allMessagesPredicate()) {
            return msgs as! [CdMessage]
        }
        return []
    }

    public func lastUID() -> UInt {
        if let msg = CdMessage.first(
            with: allMessagesPredicate(),
            orderedBy: [NSSortDescriptor(key: "uid", ascending: false)]) {
            return msg.uid.uintValue
        }
        return 0
    }
}
