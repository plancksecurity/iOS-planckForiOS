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
        return [FolderType.all]
    }

    private var mailboxTypesDeletedMailsShouldBeExpungedAfterCopyingdToTrash: [FolderType] {
        return [FolderType.all]
    }

    private var appandableVirtualMailboxTypes: [FolderType] {
        return [FolderType.drafts, .trash]
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

    func mailsCopiedToTrashShouldBeExpungedFrom(_ folder: Folder) -> Bool {
        return mailboxTypesDeletedMailsShouldBeExpungedAfterCopyingdToTrash.contains(folder.folderType)
    }

    func defaultDestructiveActionIsArchive(forFolder folder: Folder) -> Bool {
        // The only folder that should provide "trash" action (not "archive") is the Trash folder
        return belongsToProvider(folder)
            && folder.folderType != .trash
            && !mailboxTypesDeletedMailsShouldBeCopiedToTrashFrom.contains(folder.folderType)
    }
}
