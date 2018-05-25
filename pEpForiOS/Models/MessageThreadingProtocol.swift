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
    var numberOfThreadAncestors: Int { get }

    /**
     All previous messages in the thread that this message is the top of.
     - Note: Only lists ancestor messages, that is messages that went _before_ this one.
     The following holds true: `numberOfThreadAncestors().count + 1 == threadCount`.
     */
    func threadAncestors() -> [Message]

    /// Returns the most recent `sent`date of all messages.
    var lastDateSent: Date { get }

    /// Delete a message, optionally including all ancestors.
    func delete(alsoDeleteThreadAncestors: Bool)

    /// Whether or not the thread contains a flagged message.
    func hasFlagged() -> Bool

    /// Whether or not the thread contains an unread message.
    func hasUnread() -> Bool

    /// Whether or not the thread contains a message with attachments.
    func hasAttachments() -> Bool

    /**
     Reloads the thread.
     Used when altering the thread, e.g. after answering a message of the thread.
     */
    func reloadThread()
}
