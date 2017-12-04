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
        imapFieldTrashedStatus = .trashed
        imapFlags = theFlags
        self.save()
    }

    /// Sets flag "deleted".
    /// Use this method if you want the message to be copied to trash folder.
    func imapDelete() {
        let theFlags = imapFlags ?? ImapFlags()
        theFlags.deleted = true
        imapFieldTrashedStatus = .shouldBeTrashed
        imapFlags = theFlags
        self.save()
    }
}
