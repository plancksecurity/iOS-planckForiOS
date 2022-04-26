//
//  Message+IMAP.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 17.11.20.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import Foundation

// MARK: - Deletion

extension Message {
    /// Use this method if you do not want the message to be moved to trash folder.
    /// Takes into account if parent folder is remote or local.
    public func imapMarkDeleted() {
        cdObject.imapMarkDeleted()
        moc.saveAndLogErrors()
    }

    /// Triggers trashing of messages, taking everithing in account (parent is local or remote,
    /// provider specific constrains ...).
    /// Always use this method to handle "user has choosen to delete e-mails".
    public static func imapDelete(messages: [Message]) {
        messages.forEach { $0.imapDelete() }
        Stack.shared.mainContext.saveAndLogErrors()
    }
}

// MARK: - Move

extension Message {
    /// Marks the message for moving to the given folder.
    ///
    /// Does not actually move the message but set it's target folder.
    /// The Backgound layer has to take care of the actual move.
    ///
    /// Returns immediately in case the message is in the target folder already.
    ///
    /// - Parameter targetFolder: folder to move the message to
    public static func move(messages: [Message], to targetFolder: Folder) {
        messages.forEach { $0.move(to: targetFolder) }
        Stack.shared.mainContext.saveAndLogErrors()
    }
}

// MARK: - IMAP Flags

extension Message {

    /// Mark the messages passed by param as [un]flagged.
    ///
    /// - Parameters:
    ///   - messages: The message to mark
    ///   - seen: True means they must be marked as flagged. Otherwise use false.
    public static func setFlaggedValue(to messages: [Message], newValue flagged: Bool) {
        messages.forEach {
            // this logic is to trigger the FRC
            let imap =  $0.imapFlags
            imap.flagged = flagged
            $0.imapFlags = imap
        }
        Stack.shared.mainContext.saveAndLogErrors()
    }

    /// Mark the messages passed by param as [un]seen.
    ///
    /// - Parameters:
    ///   - messages: The message to mark
    ///   - seen: True means they must be marked as seen. Otherwise use false.
    public static func setSeenValue(to messages: [Message], newValue seen: Bool) {
        messages.forEach {
            // this logic is to trigger the FRC
            let imap = $0.imapFlags
            imap.seen = seen
            $0.imapFlags = imap
        }
        Stack.shared.mainContext.saveAndLogErrors()
    }

    /// Merge the UIImapState to the Imap state of the messages passed by param
    ///
    /// - Parameter messages: The messages to merge the states.
    public static func mergeUIState(messages: [Message]) {
        messages.forEach { message in
            let imapUIFlags = message.imapUIFlags
            let imap = message.imapFlags
            if let seen = imapUIFlags?.seen, seen {
                imap.seen = seen
            }
            if let flagged = imapUIFlags?.flagged, flagged {
                imap.flagged = flagged
            }
            message.imapUIFlags = nil
            message.imapFlags = imap
        }
        Stack.shared.mainContext.saveAndLogErrors()
    }

    /// Marks the message as read (only for the ui).
    /// This allows us to keep the state regarding the UI only, so updates are not automatically triggered.
    public func markUIOnlyAsSeen() {
        guard !imapFlags.seen else {
            // The message is marked as seen already. Thus there is nothing to do here.
             return
        }
        if let flags = imapUIFlags {
            flags.seen = true
            imapUIFlags = flags
        } else {
            let cdImapUIFlags = CdImapUIFlags(context: moc)
            let flags = ImapUIFlags(cdObject: cdImapUIFlags, context: moc)
            flags.seen = true
            imapUIFlags = flags
        }
        moc.saveAndLogErrors()
    }
}
