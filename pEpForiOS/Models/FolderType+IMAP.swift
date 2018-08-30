//
//  FolderType+IMAP.swift
//  pEp
//
//  Created by Andreas Buff on 06.02.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel

extension FolderType {

    // MARK: - Local or remote folder

    /// Whether or not a folder of this type represents a remote folder
    var isSyncedWithServer: Bool {
        return FolderType.typesSyncedWithImapServer.contains(self)
    }

    /// Folder of those types mirror a remote IMAP folder and have to be synced.
    static let typesSyncedWithImapServer = [FolderType.inbox,
                                                    .normal,
                                                    .sent,
                                                    .drafts,
                                                    .trash,
                                                    .spam,
                                                    .archive,
                                                    .all,
                                                    .flagged]

    /// Raw values of typesSyncedWithImapServer
    static let typesSyncedWithImapServerRawValues: [FolderType.RawValue] = {
        typesSyncedWithImapServer.map { $0.rawValue }
    }()

    // MARK: - Append Flags

    /// Flags that should be used when appending mails to a folder of this type.
    ///
    /// - Returns:  If flags are defined for this type:: the flags.
    ///             nil otherwize
    func defaultAppendImapFlags() -> Message.ImapFlags? {
        switch self {
        case .sent:
            let result = Message.ImapFlags()
            result.seen = true
            return result
        case .archive, .drafts, .inbox, .normal, .trash, .spam, .all, .flagged, .outbox:
            break
        }
        return nil
    }

    // MARK: - Required IMAP folders

    /**
     `FolderType`s that should be created if they don't yet exist.
     */
    public static let requiredTypes = [FolderType.drafts, .sent, .trash]

    // MARK: - Naming

    /**
     Each folder type has one or more human-readable name you can use to match
     remote folder names.
     - Note: This is used *only* for the local-only special folders, and for fuzzy-matching
     against a known folder type when fetching from the remote server.
     */
    public func folderNames() -> [String] {
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
            return [NSLocalizedString("Outbox",
                                      comment:
                "Name of folder that holds yet unsend messages (outbox)")]
        }
    }

    /**
     Each kind has a human-readable name you can use to create a local folder object.
     - Note: This is used *only* for the local-only special folders, and for fuzzy-matching
     against a known folder type when fetching from the remote server.
     */
    public func folderName() -> String {
        return folderNames()[0]
    }

    // MARK: - PantomimeSpecialUseMailboxType <-> FolderType

    //After new Pantomime enum approach is implemented. It is ugly that MessageModel has to know int values of Pantomime enums
    ///Folder type for PantomimeSpecialUseMailboxType
    public static func from(pantomimeSpecialUseMailboxType: Int) -> FolderType? {
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

    // MARK: - Individual Properties and Actions

    /**
     Is a mail in that folder *typically* outgoing? This can only be a guess for some cases.
     */
    public func isOutgoing() -> Bool {
        switch self {
        case .inbox, .trash, .normal, .spam, .archive, .all, .flagged:
            return false
        case .sent, .drafts, .outbox:
            return true
        }
    }
}
