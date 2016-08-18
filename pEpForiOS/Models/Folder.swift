import Foundation
import CoreData

/**
 Folder types.
 - Note: If you change this, make sure all dependent methods are adapted!
 */
public enum FolderType: Int {
    /**
     Just some folder, nothing special.
     */
    case Normal = 0

    /**
     The incoming folder mirrored from server. E.g., INBOX.
     */
    case Inbox

    /**
     Contains emails that are currently in progress, still being worked on by the user.
     */
    case LocalDraft

    /**
     Contains emails that have not been sent, but should. User has tappend send button.
     */
    case LocalOutbox

    /**
     Local sent folder
     */
    case LocalSent

    /**
     Remote sent folder
     */
    case Sent

    /**
     Remote drafts folder
     */
    case Drafts

    /**
     Remote trash folder
     */
    case Trash

    /**
     Remote Archive folder
     */
    case Archive

    /**
     Remote Spam folder
     */
    case Spam

    /**
     The list of folder kinds that have to be created locally
     */
    public static let allValuesToCreate = [LocalDraft, LocalOutbox, LocalSent]

    /**
     A list of types to check folders from remote server for categorization.
     Whenever a folder is created after having been parsed from the server,
     those types should be checked for matches.
     */
    public static let allValuesToCheckFromServer = [Drafts, Sent, Trash]

    public static func fromInt(folderTypeInt: Int) -> FolderType? {
        switch folderTypeInt {
        case FolderType.Normal.rawValue:
            return .Normal
        case FolderType.Inbox.rawValue:
            return .Inbox
        case FolderType.LocalDraft.rawValue:
            return .LocalDraft
        case FolderType.LocalOutbox.rawValue:
            return .LocalOutbox
        case FolderType.LocalSent.rawValue:
            return .LocalSent
        case FolderType.Sent.rawValue:
            return .Sent
        case FolderType.Drafts.rawValue:
            return .Sent
        case FolderType.Trash.rawValue:
            return .Trash
        case FolderType.Archive.rawValue:
            return .Archive
        case FolderType.Spam.rawValue:
            return .Spam
        default:
            return nil
        }
    }

    /**
     Each folder type has one or more human-readable name you can use to match
     remote folder names.
     - Note: This is used *only* for the local-only special folders, and for fuzzy-matching
     against a known folder type when fetching from the remote server.
     */
    public func folderNames() -> [String] {
        switch self {
        case .Normal:
            return ["Normal"]
        case .Inbox:
            // Don't actually use this for the INBOX, always use `ImapSync.defaultImapInboxName`!
            return ["Inbox"]
        case .LocalDraft:
            return ["Local Drafts"]
        case .LocalOutbox:
            return ["Local Outbox"]
        case .LocalSent:
            return ["Local Sent"]
        case .Sent:
            return ["Sent"]
        case .Drafts:
            return ["Drafts"]
        case .Trash:
            return ["Trash"]
        case .Archive:
            return ["Archive"]
        case .Spam:
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
        case .Inbox, .Trash, .Normal, .Spam, .Archive:
            return false
        case .LocalDraft, .LocalOutbox, .LocalSent, .Sent, .Drafts:
            return true
        }
    }
}

public protocol IFolder: _IFolder {
}

@objc(Folder)
public class Folder: _Folder, IFolder {
}
