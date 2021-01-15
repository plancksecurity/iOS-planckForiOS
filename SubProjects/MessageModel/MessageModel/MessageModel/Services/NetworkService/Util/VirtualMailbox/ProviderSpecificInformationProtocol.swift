//
//  ProviderSpecificInformationProtocol.swift
//  pEp
//
//  Created by Andreas Buff on 09.02.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

protocol ProviderSpecificInformationProtocol {

    /// Whether or not the given folder belongs to the provider.
    ///
    /// - Parameter folder: folder to figure out if it belongs to the provider
    /// - Returns: true if the given folder belongs to the provider, false otherwize
    func belongsToProvider(_ folder: Folder) -> Bool

    /// Like belongsToProvider(_ folder: Folder).
    func belongsToProvider(_ folder: CdFolder) -> Bool

    /// You might be able to append messages to virtual mailboxes. Due to weak specification in
    /// RFC6154 we have to use provider specific rules for certain providers.
    /// Examples:
    /// 1) Gmail Sent
    /// You MUST NOT append send messages to the "[Gmail]/Sent" folder, as Gmail does handle that
    /// automatically and thus appending it results in a duplicated sent message.
    /// 2) Gmail Drafts
    /// You MIGHT (and we do) append drafted mails to the [Gmail]/Drafts folder.
    /// Technically the message will show up in the virtual [Gmail]/Darfts folder if:
    /// - the message is contained in *any* folder
    /// - the message has imapFlag ".draft" set
    /// - the message has not the imaFlag ".deleted" set
    /// 3) Gmail Trash
    /// You MUST append drafted mails to the [Gmail]/Trash folder to make them show up there.
    /// The "Trash" folder is the only "non-virtual mailbox" on Gmail.
    ///
    /// - Parameter folder: folder to check appendability for
    /// - Returns: true if it is OK to append messages to this folder, false otherwize
    func isOkToAppendMessages(toFolder folder: Folder) -> Bool

    /// Like isOkToAppendMessages(toFolder folder: Folder)
    func isOkToAppendMessages(toFolder folder: CdFolder) -> Bool

    /// - Returns:  Whether or not deleted messages should be moved to trash using the UID MOVE
    ///             extension instead of copying it locally and then appending it.
    func shouldUidMoveMailsToTrashWhenDeleted(inFolder folder: Folder) -> Bool

    /// Whether or not the default destructive action is "archive" instead of "delete".
    func defaultDestructiveActionIsArchive(forFolder folder: Folder) -> Bool
}
