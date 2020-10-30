//
//  FolderType+IMAP.swift
//  pEp
//
//  Created by Andreas Buff on 06.02.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import CoreData

extension FolderType {

    // MARK: - Append Flags

    /// Flags that should be used when appending mails to a folder of this type.
    ///
    /// - Returns:  If flags are defined for this type:: the flags.
    ///             nil otherwize
    func defaultAppendImapFlags(context: NSManagedObjectContext) -> ImapFlags? { //!!!: refactor to return CdImapFlags
        switch self {
        case .sent:
            let cdFlags = CdImapFlags(context: context)
            let result = ImapFlags(cdObject: cdFlags, context: context)
            result.seen = true
            return result
        case .archive, .drafts, .inbox, .normal, .trash, .spam, .all, .flagged, .outbox, .pEpSync:
            break
        }
        return nil
    }

    //!!!: make all the below internal 

    // MARK: - Required IMAP folders

    /// FolderType`s that should be created if they don't yet exist.
    static let requiredTypes = [FolderType.drafts, .sent, .trash]

    // MARK: - Naming

    /// Folder names that are common to use for a specific folder type.
    func folderNames() -> [String] {
        switch self {
        case .normal:
            return ["Normal"]
        case .inbox:
            // Don't actually use this for the INBOX, always use `ImapSync.defaultImapInboxName`!
            return ["Inbox"]
        case .sent:
            return ["Sent"]
        case .drafts:
            return ["Drafts", "Draft"]
        case .trash:
            return ["Trash"]
        case .archive:
            return ["Archive"]
        case .spam:
            return ["Spam", "Junk"]
        case .all:
            return ["All"]
        case .flagged:
            return ["Flagged"]
        case .outbox:
            return ["Outbox"]
        case .pEpSync:
            // should not be shown to the user, has a fixed name
            return []
        }
    }

    /// Each kind has a human-readable name you can use to create a local folder object.
    /// - Note: This is used *only* for the local-only special folders, and for fuzzy-matching
    ///         against a known folder type when fetching from the remote server.
    public func folderName() -> String {
        return folderNames()[0]
    }

    // MARK: - PantomimeSpecialUseMailboxType <-> FolderType

    //After new Pantomime enum approach is implemented. It is ugly that MessageModel has to know int values of Pantomime enums
    ///Folder type for PantomimeSpecialUseMailboxType
    static func from(pantomimeSpecialUseMailboxType: Int) -> FolderType? {
        switch pantomimeSpecialUseMailboxType {
        case 0:
            return .normal
        case 1:
            return .all
        case 2:
            return .archive
        case 3:
            return .drafts
        case 4:
            return .flagged
        case 5:
            return .spam
        case 6:
            return .sent
        case 7:
            return .trash
        default:
            return nil
        }
    }
}
