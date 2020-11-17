//
//  Folder+VirtualMailbox.swift
//  pEp
//
//  Created by Andreas Buff on 07.02.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

// MARK: - Virtual Mailbox Extensions

/// Due to the underspecified RFC6154 there is no way to know whether or not a Special-Use-Mailbox
/// is virtual. It all depends on the servers/providers implementation.
extension Folder {

    /// We currently only take Gmail into account.
    // TODO: This is duplicated between MM and Cd.
    private var supportedProviders: [ProviderSpecificInformationProtocol] {
        return [GmailSpecificInformation()]
    }

    // TODO: This is duplicated between MM and Cd.
    private var providerSpecificInfo: ProviderSpecificInformationProtocol? {
        for providerInfo in supportedProviders {
            if providerInfo.belongsToProvider(self) {
                return providerInfo
            }
        }
        return nil
    }

    /// Whether or not the default destructive action is "archive" instead of "delete".
    public var defaultDestructiveActionIsArchive: Bool {
        let defaultValue = false
        guard let providerInfo = providerSpecificInfo else {
            return defaultValue
        }
        return providerInfo.defaultDestructiveActionIsArchive(forFolder: self)
    }

    var shouldUidMoveDeletedMessagesToTrash: Bool {
        let defaultValue: Bool
        if folderType == .trash {
            // We never want to move a message from trash to trash
            defaultValue = false
        } else {
            defaultValue = true
        }

        guard let providerInfo = providerSpecificInfo else {
            // There are no provider specific rules
            return defaultValue
        }
        return providerInfo.shouldUidMoveMailsToTrashWhenDeleted(inFolder: self)
    }
}
