//
//  Folder+VirtualMailbox.swift
//  pEp
//
//  Created by Andreas Buff on 07.02.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel

// MARK: - Virtual Mailbox Extensions

/// Due to the underspecified RFC6154 there is no way to know whether or not a Special-Use-Mailbox
/// is virtual. It all depends on the servers/providers implementation.
extension Folder {

    /// We currently only take Gmail into account.
    private var supportedProviders: [ProviderSpecificInformationProtocol] {
        return [GmailSpecificInformation()]
    }

    private var providerSpecificInfo: ProviderSpecificInformationProtocol? {
        for providerInfo in supportedProviders {
            if providerInfo.belongsToProvider(self) {
                return providerInfo
            }
        }
        return nil
    }

    /// Whether or not the default destructive action is "archive" instead of "delete".
    var defaultDestructiveActionIsArchive: Bool {
        let defaultValue = false
        guard let providerInfo = providerSpecificInfo else {
            return defaultValue
        }
        return providerInfo.defaultDestructiveActionIsArchive(forFolder: self)
    }

    /// If true, things will go wrong if you append messages to this folder.
    ///
    /// Appending a message anyway will cause unexpected behaviour. Depending on the provider
    /// and folder type:
    /// - Error returned from server
    /// - Duplicated messages (as the server handles append)
    /// - Possibly all kinds of undefined behavior
    var shouldNotAppendMessages: Bool {
        let defaultValue = false
        guard let providerInfo = providerSpecificInfo else {
            // There are no provider specific rules
            return defaultValue
        }
        return !providerInfo.isOkToAppendMessages(toFolder: self)
    }

    /// - Returns:  Whether or not (marked) deleted messages in this folder should also be
    ///             copied to trash.
    var shouldCopyDeletedMessagesToTrash: Bool {
        // The default is to copy deleted messages to trash in all folders but trash folder itself.
        let defaultValue = folderType == .trash ? false : true
        guard let providerInfo = providerSpecificInfo else {
            // There are no provider specific rules
            // or we are supposed to use the default behaviour (not virtual mailbox)
            return defaultValue
        }
        return providerInfo.deletedMailsShouldBeCopiedToTrashFrom(self)
    }

    var shouldUidMoveDeletedMessagesToTrash: Bool {
        // We only want to expunge if the provider offers no alternative.
        let defaultValue = false
        guard let providerInfo = providerSpecificInfo else {
            // There are no provider specific rules
            return defaultValue
        }
        return providerInfo.shouldUidMoveMailsToTrashWhenDeleted(inFolder: self)
    }
}
