//
//  Message+IMAP+Internal.swift
//  pEp
//
//  Created by Andreas Buff on 04.12.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import pEpIOSToolbox

extension Message {
    // MARK: - Deletion

    /// Only for internal use, does not save!
    func imapDelete() {
        if self.isDeleted {
            // Do not bother messages that have been deleted from the DB alreadyby some background
            // action (e.g. deleted in other MUA)
            return
        }
        if parent.folderType.isSyncedWithServer {
            internalImapDelete()
        } else {
            Stack.shared.mainContext.delete(cdObject)
        }
        moc.saveAndLogErrors()
    }

    /// Triggers trashing of the message, taking everithing in account (provider specific constrains
    /// and such).
    /// Always use this method to handle "user has choosen to delete an e-mail".
    /// Note: Use only for messages synced with an IMAP server.
    private func internalImapDelete() {
        guard self.parent.folderType.isSyncedWithServer else {
            Log.shared.errorAndCrash(
                "This method must not be called for messages in local folders.")
            return
        }
        guard let trashFolder = parent.account.firstFolder(ofType: .trash) else {
            Log.shared.errorAndCrash(
                "We should have a trash folder at this point")
            return
        }

        if parent.shouldUidMoveDeletedMessagesToTrash && !isFakeMessage {
            move(to: trashFolder)
        } else {
            imapMarkDeleted()
        }
    }

    // MARK: - Move to Folder

    /// Does not save!
    func move(to targetFolder: Folder) {
        guard parent != targetFolder else {
            // the message is in the target folder already. No need to move it.
            return
        }
        createFakeMessage(in: targetFolder)
        if targetFolder.account == parent.account {
            self.targetFolder = targetFolder
        } else {
            // The message must be moved to another account. Thus ...
            // ... we save a copy for append in target accounts folder ...
            let copy = Message(message: self)
            copy.parent = targetFolder
            // ... and delete the original.
            self.imapMarkDeleted()
        }
    }
}

// MARK: - IMAP Flags

extension Message {

    public static func setFlaggedValue(to messages: [Message], newValue flagged: Bool) {
        messages.forEach {
            // this logic is to trigger the FRC
            let imap =  $0.imapFlags
            imap.flagged = flagged
            $0.imapFlags = imap
        }
        Stack.shared.mainContext.saveAndLogErrors()
    }

    public static func setSeenValue(to messages: [Message], newValue seen: Bool) {
        messages.forEach {
            // this logic is to trigger the FRC
            let imap = $0.imapFlags
            imap.seen = seen
            $0.imapFlags = imap
        }
        Stack.shared.mainContext.saveAndLogErrors()
    }
}
