//
//  Folder+VirtualMailbox.swift
//  pEp
//
//  Created by Andreas Buff on 07.02.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel

// MARK: - Virtual Mailbox Extensions

/// Due to the underspecified RFC6154 there is no way to know whether or not a Special-Use-Mailbox is virtual.
/// It all depends on the servers/providers implementation.
extension Folder {

    /// If true,things will go wrong if you append messages to this folder.
    ///
    /// Appending a message anyway will cause unexpected behaviour. Depending on the provider
    /// and folder type:
    /// - Error returned from server
    /// - Duplicated messages (as the server handles append)
    /// - Possibly all kinds of undefined behavior
    var shouldNotAppendMessages: Bool {
        var appendable = true
        if isGmailVirtualMailbox {
            appendable = appandableVirtualMailboxTypesGmail.contains(folderType)
        }

        return !appendable
    }

    /// Whether or not this folder represents a virtual mailbox, taking provider specific server
    /// implementations into account.
    private var isVirtualMailbox: Bool {
        if folderType.isMostLikelyVirtualMailbox {
            return true
        }
        return isGmailVirtualMailbox
    }

    // MARK: - GMAIL

    /// You might be able to append messages to virtual mailboxes. Due to weak specification in
    /// RFC6154 we have to use provider specific rules for certain providers.
    /// Examples:
    /// 1) Gmail Sent
    /// You MUST NOT append send messages to the "[Gmail]/Sent" folder, as Gmail does handle that
    /// automatically and thus appending it results in a duplicated sent message.
    /// 2) Gmail Drafts
    /// You MIGHT (and we do) append drafted mails to the [Gmail]/Darfts folder.
    /// Technically the message will show up in the virtual [Gmail]/Darfts folder if:
    /// - the message is contained in any folder
    /// - the message has imapFlag ".draft" set
    /// - the message has not the imaFlag ".deleted" set
    private var appandableVirtualMailboxTypesGmail: [FolderType] {
        return [FolderType.drafts] //BUFF: trash too?
    }

    /// All subfolders of folder named "[Gmail]" are virtual.
    private var isGmailVirtualMailbox: Bool {
        return account.user.address.isGmailAddress
            && parent != nil
            && name.hasPrefix("[Gmail]")
    }
}
