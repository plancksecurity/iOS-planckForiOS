//
//  CdFolder+Extension.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 17/10/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

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
        if let folder = by(name: folderName, account: account) {
            return reactivate(folder: folder)
        }

        if let separator = folderSeparator {
            account.folderSeparator = folderSeparator

            // Create folder hierarchy if necessary
            var pathsSoFar = [String]()
            var parentFolder: CdFolder? = nil
            let paths = folderName.components(separatedBy: separator)
            for p in paths {
                pathsSoFar.append(p)
                let pathName = (pathsSoFar as NSArray).componentsJoined(
                    by: separator)
                let folder = CdFolder.create(with: ["name": pathName, "account": account])
                folder.parent = parentFolder
                if let pf = parentFolder {
                    pf.addToSubFolders(folder)
                }
                parentFolder = folder
            }
            return parentFolder
        } else {
            // Just create the folder as-is, can't check for hierarchy
            let folder = CdFolder.create(with: ["name": folderName, "account": account])
            return folder
        }
    }

    /**
     Extracts a unique String ID that you can use as a key in dictionaries.
     - Returns: A (hashable) String that is unique for each folder.
     */
    public func hashableID() -> String {
        return "\(folderType) \(name) \(account?.identity?.address)"
    }

    /**
     - Returns: The predicate (for CdMessage) to get all (undeleted, valid)
     messages contained in that folder.
     */
    public func allMessagesPredicate() -> NSPredicate {
        return NSPredicate(format: "folder = %@, imapFlags.flagDeleted = false", self)
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
