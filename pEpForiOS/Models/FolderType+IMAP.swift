//
//  FolderType+IMAP.swift
//  pEp
//
//  Created by Andreas Buff on 06.02.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel

extension FolderType {
    /// Whether or not the folder type is most likely realized as virtual mailbox on server side.
    /// See RFC-6154
    var isMostLikelyVirtualMailbox: Bool {
        let virtualMailboxesTypes = [FolderType.all,        // RFC for \All: "When this special use is supported, it is almost certain to represent a virtual mailbox"
            FolderType.flagged]    // RFC for \Flagged: it is likely to represent a virtual mailbox collecting messages (from other mailboxes) that are marked with the "\Flagged" message flag.
        return virtualMailboxesTypes.contains(self)
    }
}
