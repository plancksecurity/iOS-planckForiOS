//
//  FolderType.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 17/10/16.
//  Copyright © 2016 pEp Security S.A. All rights reserved.
//

import UIKit

/**
 Folder types.
 - Note: If you change this, make sure all dependent methods are adapted!
 */
public enum FolderType: Int16, CaseIterable{
    /**
     Just some folder, nothing special.
     */
    case normal = 0

    /**
     The incoming folder mirrored from server. E.g., INBOX.
     */
    case inbox

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
     Remote Spam folder.
     */
    case spam

    /**
     This mailbox presents all messages in the user's message store.
     Implementations MAY omit some messages, such as, perhaps, those
     in \Trash and \Junk.  When this special use is supported, it is
     almost certain to represent a virtual mailbox.
     See: RFC6154-Special-Use Mailboxes
     */
    case all

    /**
     This mailbox presents all messages marked in some way as
     "important".  When this special use is supported, it is likely
     to represent a virtual mailbox collecting messages (from other
     mailboxes) that are marked with the "\Flagged" message flag.
     See: RFC6154-Special-Use Mailboxes
     */
    case flagged

    /// A special local folder that holds messages that should be send
    case outbox

    /// Folder exclusively used for pEp sync messages
    case pEpSync
}

 // MARK: - Local or remote folder

// MM should not know about servers and whether or not they are local.
// Needs to be moved to app target.
extension FolderType {

    /// Whether or not a folder of this type represents a remote folder
    public var isSyncedWithServer: Bool {
        return FolderType.typesSyncedWithImapServer.contains(self)
    }

    public var isLocalFolder: Bool {
        return !isSyncedWithServer
    }

    /// Folder of those types mirror a remote IMAP folder and have to be synced.
    public static let typesSyncedWithImapServer = [FolderType.inbox,
                                                   .normal,
                                                   .sent,
                                                   .drafts,
                                                   .trash,
                                                   .spam,
                                                   .archive,
                                                   .all,
                                                   .flagged,
                                                   .pEpSync]

    /// Raw values of typesSyncedWithImapServer
    public static let typesSyncedWithImapServerRawValues: [FolderType.RawValue] = {
        typesSyncedWithImapServer.map { $0.rawValue }
    }()

    public var neverShowToUser: Bool {
        if self == .pEpSync {
            return true
        }
        return false
    }
}
