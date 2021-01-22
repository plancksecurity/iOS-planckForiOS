//
//  GmailSpecificInformation.swift
//  pEp
//
//  Created by Andreas Buff on 09.02.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

struct GmailSpecificInformation {

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
        return [.inbox, .drafts, .normal]
    }
}

// MARK: - ProviderSpecificInformationProtocol

extension GmailSpecificInformation: ProviderSpecificInformationProtocol {

    func belongsToProvider(_ folder: Folder) -> Bool {
        return belongsToProvider(folder.cdObject)
    }

    func belongsToProvider(_ folder: CdFolder) -> Bool {
        return folder.accountOrCrash.accountType == .gmail
    }

    func isOkToAppendMessages(toFolder folder: Folder) -> Bool {
        return isOkToAppendMessages(toFolder: folder.cdObject)
    }

    func isOkToAppendMessages(toFolder folder: CdFolder) -> Bool {
        return appandableVirtualMailboxTypes.contains(folder.folderType) ||
            folder.folderType == .pEpSync
    }

    func shouldUidMoveMailsToTrashWhenDeleted(inFolder folder: Folder) -> Bool {
        return mailboxTypesDeletedMailsShouldBeUidMovedToTrash.contains(folder.folderType)
    }

    func defaultDestructiveActionIsArchive(forFolder folder: Folder) -> Bool {
        return belongsToProvider(folder)
            && !mailboxTypesWithDefaultDestructiveActionTrash.contains(folder.folderType)
    }
}
