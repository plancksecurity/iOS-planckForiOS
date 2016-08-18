import Foundation
import CoreData

/**
 Folder types.
 - Note: If you change this, make sure all dependent methods are adapted!
 */
public enum FolderType: Int {
    /**
     The incoming folder mirrored from server. E.g., INBOX.
     */
    case Inbox = 0

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
        default:
            return nil
        }
    }

    /**
     Each kind has a human-readable name you can use to create a local folder object.
     All except the Default, where you really should use `ImapSync.defaultImapInboxName`.
     - Note: This is used *only* for the local-only special folders.
     */
    public func folderName() -> String {
        switch self {
        case .Inbox:
            // Don't actually use this for the INBOX, always use `ImapSync.defaultImapInboxName`!
            return "Inbox"
        case .LocalDraft:
            return "Local Drafts"
        case .LocalOutbox:
            return "Local Outbox"
        case .LocalSent:
            return "Local Sent"
        case .Sent:
            return "Sent"
        case .Drafts:
            return "Drafts"
        case .Trash:
            return "Trash"
        }
    }

    /**
     Is a mail in that folder *typically* outgoing? This can only be a guess for some cases.
     */
    public func isOutgoing() -> Bool {
        switch self {
        case .Inbox, .Trash:
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
