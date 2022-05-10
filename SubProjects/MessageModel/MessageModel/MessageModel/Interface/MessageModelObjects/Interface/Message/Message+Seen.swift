//
//  Message+Seen.swift
//  MessageModel
//
//  Created by Martín Brude on 14/4/22.
//  Copyright © 2022 pEp Security S.A. All rights reserved.
//

import Foundation

// MARK: - IMAP flags

extension Message {
    /**
     Marks the message as read, which in IMAP terms is called "seen".
     */
    public func markAsSeen() {
        let imap = imapFlags
        guard !imap.seen else {
            // The message is marked as seen already. Thus there is nothing to do here.
            // This ways we also avoid potentionally triggering a message change.
            return
        }
        imap.seen = true
        imapFlags = imap
        moc.saveAndLogErrors()
    }
}
