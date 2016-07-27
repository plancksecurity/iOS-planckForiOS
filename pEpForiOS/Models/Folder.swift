import Foundation
import CoreData

public enum FolderType: Int {
    /**
     Incoming folder mirrored from server. E.g., INBOX.
     */
    case Default = 0

    /**
     Contains emails that are currently in progress, still being worked on by the user.
     */
    case LocalDraft

    /**
     Contains emails that have not been sent, but should. User has tappend send button.
     */
    case LocalOutbox

    /**
     Local sent folder.
     */
    case LocalSent

    /**
     The list of folder kinds that have to be created locally
     */
    public static let allValuesToCreate = [LocalDraft, LocalOutbox, LocalSent]

    public static func fromInt(folderTypeInt: Int) -> FolderType? {
        switch folderTypeInt {
        case FolderType.Default.rawValue:
            return .Default
        case FolderType.LocalDraft.rawValue:
            return .LocalDraft
        case FolderType.LocalOutbox.rawValue:
            return .LocalOutbox
        case FolderType.LocalSent.rawValue:
            return .LocalSent
        default:
            return nil
        }
    }

    /**
     Each kind has a human-readable name you can use to create a local folder object.
     All except the Default, where you really should use `ImapSync.defaultImapInboxName`.
     */
    public func folderName() -> String {
        switch self {
        case .Default:
            // Don't actually use this for the INBOX, always use `ImapSync.defaultImapInboxName`!
            return "Default"
        case .LocalDraft:
            return "Local Drafts"
        case .LocalOutbox:
            return "Local Outbox"
        case .LocalSent:
            return "Local Sent"
        }
    }

    /**
     Is a mail in that folder typically outgoing?
     */
    public func isOutgoing() -> Bool {
        switch self {
        case .Default:
            return false
        case .LocalDraft:
            return true
        case .LocalOutbox:
            return true
        case .LocalSent:
            return true
        }
    }
}

public protocol IFolder: _IFolder {
}

@objc(Folder)
public class Folder: _Folder, IFolder {
}
