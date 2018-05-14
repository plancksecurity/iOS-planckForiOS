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
    func imapDeleteAndMarkTrashed() {  //IOS-663: rename
        let theFlags = imapFlags ?? ImapFlags()
        theFlags.deleted = true
        self.save()
    }

    /// Marks message to move to Trash folder
    func imapDelete() { //IOS-663: renmae (imapTrash?)
        guard let trashFolder = parent.account.folder(ofType: .trash) else {
            Log.shared.errorAndCrash(component: #function,
                                     errorString: "We should have a trash folder at this point")
            return
        }
        move(to: trashFolder)
    }

    /// Marks the message for moving to the given folder.
    ///
    /// - Parameter targetFolder: folder to move the message to
    func move(to targetFolder:Folder) {
        if parent == targetFolder {
            // the message is in the target folder already. No need to move it.
            return
        }
        self.targetFolder = targetFolder
        save()
    }
}
