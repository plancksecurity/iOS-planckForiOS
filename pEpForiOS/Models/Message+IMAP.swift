//
//  Message+IMAP.swift
//  pEp
//
//  Created by Andreas Buff on 04.12.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import MessageModel

extension Message {
    /// Sets flag "deleted" and sets trashed status to "trashed".
    /// Use this method if you do not want the message to be copied to trash folder.
    func imapDeleteAndMarkTrashed() {
        let theFlags = imapFlags ?? ImapFlags()
        theFlags.deleted = true
        imapFields?.trashedStatus = .trashed
        imapFlags = theFlags
        self.save()
    }

    /// Sets flag "deleted" and marks the message to be copied to trash if appropriate.
    func imapDelete() {
        let theFlags = imapFlags ?? ImapFlags()
        theFlags.deleted = true
        imapFlags = theFlags
        imapFields?.trashedStatus =
            parent.shouldCopyDeletedMessagesToTrash ? .shouldBeTrashed : .trashed
        imapFields?.uidMoveToTrashStatus =
            parent.shouldUidMoveDeletedMessagesToTrash ? .shouldBeMoved : .none
        self.save()
    }

    /// Marks the message for moving to the given folder.
    ///
    /// - Parameter targetFolder: folder to move the message to
    func move(to targetFolder:Folder) {
        if parent == targetFolder {
            // the message is already in the target folder. No need to move it.
            return
        }
        self.targetFolder = targetFolder
        save()
    }
}
