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
