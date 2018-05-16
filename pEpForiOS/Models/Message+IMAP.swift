//
//  Message+IMAP.swift
//  pEp
//
//  Created by Andreas Buff on 04.12.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import MessageModel

extension Message {
    
    /// Sets flag "deleted".
    /// Use this method if you do not want the message to be moved to trash folder.
    func imapMarkDeleted() {
        let theFlags = imapFlags ?? ImapFlags()
        theFlags.deleted = true
        self.save()
    }
    
    /// Triggers trashing of the message, taking everithing in account (provider specific constrains and such).
    /// Always use this method to handle "user has choosen to delete an e-mail".
    func imapDelete() {
        guard let trashFolder = parent.account.folder(ofType: .trash) else {
            Log.shared.errorAndCrash(component: #function,
                                     errorString: "We should have a trash folder at this point")
            return
        }
        
        if parent.shouldUidMoveDeletedMessagesToTrash {
            move(to: trashFolder)
        } else {
            imapMarkDeleted()
        }
    }
    
    /// Marks the message for moving to the given folder.
    ///
    /// Does not actually move the message but set it's target folder.
    /// The Backgound layer has to take care of the actual move.
    /// 
    /// Returns immediately in case the message is in the target folder already.
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
