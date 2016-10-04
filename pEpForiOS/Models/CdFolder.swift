import Foundation

/**
 Folder types.
 - Note: If you change this, make sure all dependent methods are adapted!
 */
public enum FolderType: Int {
    /**
     Just some folder, nothing special.
     */
    case normal = 0

    /**
     The incoming folder mirrored from server. E.g., INBOX.
     */
    case inbox

    /**
     Contains emails that have not been sent, but should. User has tappend send button.
     */
    case localOutbox

    /**
     Remote sent folder
     */
    case sent

    /**
     Remote drafts folder
     */
    case drafts

    /**
     Remote trash folder
     */
    case trash

    /**
     Remote Archive folder
     */
    case archive

    /**
     Remote Spam folder
     */
    case spam

    /**
     The list of folder kinds that have to be created locally
     */
    public static let allValuesToCreate = [localOutbox]

    /**
     A list of types to check folders from remote server for categorization.
     Whenever a folder is created after having been parsed from the server,
     those types should be checked for matches.
     */
    public static let allValuesToCheckFromServer = [drafts, sent, trash]

    public static func fromInt(_ folderTypeInt: Int) -> FolderType? {
        switch folderTypeInt {
        case FolderType.normal.rawValue:
            return .normal
        case FolderType.inbox.rawValue:
            return .inbox
        case FolderType.localOutbox.rawValue:
            return .localOutbox
        case FolderType.sent.rawValue:
            return .sent
        case FolderType.drafts.rawValue:
            return .sent
        case FolderType.trash.rawValue:
            return .trash
        case FolderType.archive.rawValue:
            return .archive
        case FolderType.spam.rawValue:
            return .spam
        default:
            return nil
        }
    }

    public static func fromNumber(_ num: NSNumber?) -> FolderType? {
        if let n = num {
            return fromInt(n.intValue)
        }
        return nil
    }

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
        case .localOutbox:
            return ["Outbox"]
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

    /**
     Is a mail in that folder *typically* outgoing? This can only be a guess for some cases.
     */
    public func isOutgoing() -> Bool {
        switch self {
        case .inbox, .trash, .normal, .spam, .archive:
            return false
        case .localOutbox, .sent, .drafts:
            return true
        }
    }

    /**
     - Returns: true for any folder that is not just local.
     */
    public func isRemote() -> Bool {
        switch self {
        case .localOutbox:
            return false
        default:
            return true
        }
    }
}

@objc(CdFolder)
open class CdFolder: _CdFolder {
	// Custom logic goes here.
}

public extension CdFolder {
    /**
     Extracts a unique String ID that you can use as a key in dictionaries.
     - Returns: A (hashable) String that is unique for each folder.
     */
    public func hashableID() -> String {
        return "\(folderType.intValue) \(name) \(account.email)"
    }
}
