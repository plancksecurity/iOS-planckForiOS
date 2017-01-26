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
     */
    public static func reactivate(folder: CdFolder) -> CdFolder {
        folder.shouldDelete = false
        return folder
    }

    public static func by(folderType: FolderType, account: CdAccount,
                          context: NSManagedObjectContext = Record.Context.default) -> CdFolder? {
        return CdFolder.first(attributes: ["folderType": folderType.rawValue, "account": account],
                              in: context)
    }

    public static func by(name: String, account: CdAccount) -> CdFolder? {
        return CdFolder.first(attributes: ["name": name, "account": account])
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

    static func insert(folderName: String, account: CdAccount) -> CdFolder {
        Log.verbose(component: comp, content: "insert \(folderName)")

        // Reactivate if previously deleted
        if let folder = by(name: folderName, account: account) {
            return reactivate(folder: folder)
        }

        let folder = CdFolder.create(attributes: ["name": folderName, "account": account,
                                            "uuid": MessageID.generate()])

        if folderName.uppercased() == ImapSync.defaultImapInboxName.uppercased() {
            folder.folderType = FolderType.inbox.rawValue
        } else {
            var foundMatch = false
            for ty in FolderType.allValuesToCheckFromServer {
                for theName in ty.folderNames() {
                    if folderName.matchesPattern("\(theName)",
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

        Log.verbose(component: comp, content: "insert \(folderName): \(folder.folderType)")
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
        if let msgs = CdMessage.all(predicate: allMessagesPredicate()) {
            return msgs as! [CdMessage]
        }
        return []
    }

    public func firstUID() -> UInt {
        if let msg = CdMessage.first(
            predicate: allMessagesPredicate(),
            orderedBy: [NSSortDescriptor(key: "uid", ascending: true)]) {
            return UInt(msg.uid)
        }
        return 0
    }

    public func lastUID() -> UInt {
        if let msg = CdMessage.first(
            predicate: allMessagesPredicate(),
            orderedBy: [NSSortDescriptor(key: "uid", ascending: false)]) {
            return UInt(msg.uid)
        }
        return 0
    }
}
