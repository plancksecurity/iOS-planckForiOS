//
//  Message+IMAP.swift
//  pEp
//
//  Created by Andreas Buff on 04.12.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import MessageModel

extension Message {
    static let uidNeedsAppend = 0
    static let uidFakeResponsivenes = -1

    // MARK: - Deletion

    /// Use this method if you do not want the message to be moved to trash folder.
    /// Takes into account if parent folder is remote or local.
    func imapMarkDeleted() {
        if parent.folderType.isSyncedWithServer {
            internalImapMarkDeleted()
        } else {
            delete()
        }
    }

    /// Triggers trashing of the message, taking everithing in account (parent is local or remote,
    /// provider specific constrains ...).
    /// Always use this method to handle "user has choosen to delete an e-mail".
    func imapDelete() {
        if parent.folderType.isSyncedWithServer {
            internalImapDelete()
        } else {
            delete()
        }
    }

    /// Sets flag "deleted".
    /// Use this method if you do not want the message to be moved to trash folder.
    /// Note: Use only for messages synced with an IMAP server.
    private func internalImapMarkDeleted() {
        guard self.parent.folderType.isSyncedWithServer else {
            Logger.modelLogger.errorAndCrash(
                "This method must not be called for messages in local folders.")
            return
        }
        let theFlags = imapFlags ?? ImapFlags()
        theFlags.deleted = true
        self.save()
    }

    /// Triggers trashing of the message, taking everithing in account (provider specific constrains
    /// and such).
    /// Always use this method to handle "user has choosen to delete an e-mail".
    /// Note: Use only for messages synced with an IMAP server.
    private func internalImapDelete() {
        guard self.parent.folderType.isSyncedWithServer else {
            Logger.modelLogger.errorAndCrash(
                "This method must not be called for messages in local folders.")
            return
        }
        guard let trashFolder = parent.account.folder(ofType: .trash) else {
            Logger.modelLogger.errorAndCrash(
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

    /// Marks the message for moving to the given folder.
    ///
    /// Does not actually move the message but set it's target folder.
    /// The Backgound layer has to take care of the actual move.
    /// 
    /// Returns immediately in case the message is in the target folder already.
    ///
    /// - Parameter targetFolder: folder to move the message to
    func move(to targetFolder:Folder) {
        guard parent != targetFolder else {
            // the message is in the target folder already. No need to move it.
            return
        }
        saveFakeMessage(in: targetFolder)
        if targetFolder.account == parent.account {
           self.targetFolder = targetFolder
            save()
        } else {
            // The message must be moved to another account. Thus ...
            // ... we save a copy for append in target accounts folder ...
            let copy = Message(message: self)
            copy.parent = targetFolder
            copy.save()
            // ... and delete the original.
            self.imapMarkDeleted()
        }
    }
}
