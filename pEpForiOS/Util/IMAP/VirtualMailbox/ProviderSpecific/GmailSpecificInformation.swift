//
//  GmailSpecificInformation.swift
//  pEp
//
//  Created by Andreas Buff on 09.02.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel

struct GmailSpecificInformation {

    private var mailboxTypesDeletedMailsShouldBeCopiedToTrashFrom: [FolderType] {
        // In Gmail we must not copy any mail to trash.
        // In all folders but "All Messages":
        // - the server takes care to UID MOVE messages that are flagged \deleted
        // In "All Messages" folder:
        // - We have to UID MOVE the message to trash folder
        return []
    }

    private var mailboxTypesDeletedMailsShouldBeUidMovedToTrash: [FolderType] {
        // In Gmail the server takes care to UID MOVE messages that are flagged \deleted for all
        // folders but "All Messages", thus the only use case we have to actively UID MOVE a
        // message to trash id from "All Messages"
        return [.all, .drafts]
    }

    /// Foldertypes that should provide "trash" action (not "archive") is the Trash folder
    private var mailboxTypesWithDefaultDestructiveActionTrash: [FolderType] {
        return [.all, .drafts, .trash]
    }

    private var appandableVirtualMailboxTypes: [FolderType] {
        return [FolderType.drafts]
    }
}

// MARK: - ProviderSpecificInformationProtocol

extension GmailSpecificInformation: ProviderSpecificInformationProtocol {

    func belongsToProvider(_ folder: Folder) -> Bool {
        return folder.account.user.address.isGmailAddress
    }

    func isOkToAppendMessages(toFolder folder: Folder) -> Bool {
        return appandableVirtualMailboxTypes.contains(folder.folderType)
    }

    func isVirtualMailbox(_ folder: Folder) -> Bool {
        return self.belongsToProvider(folder)
            && folder.parent != nil
            && folder.name.hasPrefix("[Gmail]")
    }

    func deletedMailsShouldBeCopiedToTrashFrom(_ folder: Folder) -> Bool {
        return mailboxTypesDeletedMailsShouldBeCopiedToTrashFrom.contains(folder.folderType)
    }

    func shouldUidMoveMailsToTrashWhenDeleted(inFolder folder: Folder) -> Bool {
        return mailboxTypesDeletedMailsShouldBeUidMovedToTrash.contains(folder.folderType)
    }

    func defaultDestructiveActionIsArchive(forFolder folder: Folder) -> Bool {
        return belongsToProvider(folder)
            && !mailboxTypesWithDefaultDestructiveActionTrash.contains(folder.folderType)
    }
}
