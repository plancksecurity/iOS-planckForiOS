//
//  CdFolder+ImapFolder.swift
//  MessageModel
//
//  Created by Andreas Buff on 24.06.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import CoreData

import pEpIOSToolbox

// MARK: - CdFolder+ImapFolder

extension CdFolder {
    struct ImapFolderInfo {
        let name: String
        let separator: String?
        let folderType: FolderType?
        let selectable: Bool
    }

    static func updateOrCreateCdFolder(with folderInfo: CdFolder.ImapFolderInfo,
                                       inAccount cdAccount: CdAccount,
                                       context: NSManagedObjectContext = Stack.shared.newPrivateConcurrentContext) {
        CdFolder.updateOrCreate(folderName: folderInfo.name,
                                folderSeparator: folderInfo.separator,
                                folderType: folderInfo.folderType,
                                selectable: folderInfo.selectable,
                                account: cdAccount,
                                context: context)
    }

    /// Updates to a new folder type.
    ///
    /// - Note: The folder type is only changed when not nil. In practice this means
    /// that there can be no unsetting of a special folder type, e.g. by syncing
    /// with the server. This helps preserve the special type of local folders the server
    /// sees as normal.
    ///
    /// - Parameter folderType: The new folder type to set (optional).
    private func update(folderType: FolderType?) {
        if let theType = folderType {
            self.folderType = theType
        }
    }

    /// Determines if the given folder components are the pEp sync folder.
    /// - Parameter folderComponents: The paths of the folder
    /// (derived by splitting the complete folder name by the folder separator)
    static func isPEPSync(folderComponents: [String]) -> Bool {
        return folderComponents.count == 2 && folderComponents[0].isInboxFolderName() &&
            folderComponents[1] == CdFolder.pEpSyncFolderName
    }

    @discardableResult
    static func updateOrCreate(folderName: String,
                               folderSeparator: String?,
                               folderType: FolderType?,
                               selectable: Bool = true,
                               account: CdAccount,
                               context: NSManagedObjectContext? = nil) -> CdFolder? {
        guard let moc = context ?? account.managedObjectContext else {
            Log.shared.errorAndCrash("ManagedObject without context")
            return nil
        }
        var result: CdFolder?
        moc.performAndWait {
            // Update ...

            // Treat Inbox specially, since its name is case insensitive.
            // For all other folders, it's undefined if they have to be handled
            // case insensitive or not, so no special handling for those.
            if folderName.isInboxFolderName() {
                if let folder = by(folderType: .inbox, account: account, context: moc) {
                    result = folder
                    return
                }
            }

            if let folder = by(name: folderName, account: account, context: moc) {
                folder.update(folderType: folderType)
                folder.selectable = selectable
                result = folder
                return
            }

            // ... or ...

            // ... Create

            var theFolderType = folderType

            if let separator = folderSeparator {
                // Create folder hierarchy if necessary
                var pathsSoFar = [String]()
                var parentFolder: CdFolder? = nil
                let paths = folderName.components(separatedBy: separator)

                if theFolderType == nil && isPEPSync(folderComponents: paths) {
                    theFolderType = .pEpSync
                }

                for p in paths {
                    pathsSoFar.append(p)
                    let pathName = pathsSoFar.joined(separator: separator)
                    let folder = findOrInsert(folderName: pathName,
                                              folderType: nil,
                                              account: account,
                                              context: moc)

                    //if it is the actual folder (has no child folder), set its folder type
                    if p == paths.last {
                        folder.update(folderType: theFolderType)

                        // Inbox must always be selectable
                        folder.selectable = folder.folderType == .inbox ? true :  selectable
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
                    result = createdFolder
                    return
                } else {
                    result = nil
                    return
                }
            } else {
                // Just create the folder as-is, can't check for hierarchy
                let folder = findOrInsert(folderName: folderName,
                                          folderType: folderType,
                                          account: account,
                                          context: moc)
                result = folder
                return
            }
        }
        return result
    }

    static private func findOrInsert(folderName: String,
                                     folderType: FolderType?,
                                     account: CdAccount,
                                     context: NSManagedObjectContext) -> CdFolder {
        if let folder = by(name: folderName, account: account, context: context) {
            if let type = folderType {
                folder.folderType = type
            }
            return folder
        }
        let folder = CdFolder(context: context)
        folder.name = folderName
        folder.account = account
        if let type = folderType {
            folder.folderType = type
        }
        if folder.folderType != FolderType.normal || folderType != nil {
            // Someone explicitly set the type already
            // OR
            // the folderType to use is given.
            // -> No need to do heuristics by folder name to find its purpose.
            return folder
        }
        figureOutIfInboxAndSetType(for: folder)

        return folder
    }

    /// For inbox, *we* MUST set the folder type. For all other "required" folders the IMAP server
    /// informs us about which folder has which type.
    ///
    /// - Parameter folder: folder to figure out if its inbox (and to handle if so)
    static private func figureOutIfInboxAndSetType(for folder: CdFolder) {
        guard let folderName = folder.name else {
            Log.shared.errorAndCrash("We need the name to guess the type")
            return
        }
        if folderName.uppercased() == ImapConnection.defaultInboxName.uppercased() {
            folder.folderType = FolderType.inbox
        }
    }
}
