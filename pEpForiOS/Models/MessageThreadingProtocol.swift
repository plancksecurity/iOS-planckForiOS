//
//  MessageThreadingProtocol.swift
//  pEp
//
//  Created by Dirk Zimmermann on 25.05.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel

/**
 A message object can implement this in order to support a threaded view.
 */
public protocol MessageThreadingProtocol {
    /**
     The number of messages contained in the thread that this message is the top of,
     including the message itself.
     - See: `threadAncestors`
     */
    var threadCount: Int { get }

    /**
     All previous messages in the thread that this message is the top of.
     - Note: Only lists ancestor messages, that is messages that went _before_ this one.
     The following holds true: `threadAncestors().count + 1 == threadCount`.
     */
    func threadAncestors() -> [Message]
}

/*
 See my suggestion below.
 I do not understand the purpose of FolderThreadingProtocol. Thus I left it unaltered.
 */

/// Figure out if a message needs special thread handling
extension Message {
    var isPartOfThread: Bool {
        return true // Implementation must return whether or not this message is part of a thread
    }
}

/// Renamed. It is a thread.
public protocol MessageThreadProtocol {

    /*
     Apple Mail also suggests messages in other accounts. If you e.g.
     - Have two accounts X and Y
     - Forward a mail from X to Y
     - Trash it in X
     - Answer the message in Y
     Than Apple Mail also suggests the one in X.Trash, titles with "found in Trash".
     If we want this too, we need more here.
     */

    /// Inits the thread with a(n arbitrary?) message that belongs to a thread.
    init(with message: Message)

    /// Num messages in thread
    var count: Int {get}

    /// Returns the most recent `sent`date of all messages.
    var lastDateSent: Date {get}

    var lastMessage: Message {get}

    /// Get the message at a given index
    subscript(index: Int) -> Message {get}

    /// Delete a message. Also updates the thread.
    func imapDelete(message: Message)

    // Optional. Maybe useless
    func flag(message: Message)

    /// Whether or not the thread contains a flagged message.
    func hasFlagged() -> Bool

    /// Whether or not the thread contains an unread message.
    func hasUnread() -> Bool

    /// Whether or not the thread contains a message with attachments.
    func hasAttachments() -> Bool

    /// Reloads the thread. Used when altering the thread, e.g. after answering a message of the thread.
    func reset()
}
