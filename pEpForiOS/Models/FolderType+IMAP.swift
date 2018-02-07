//
//  FolderType+IMAP.swift
//  pEp
//
//  Created by Andreas Buff on 06.02.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel

extension FolderType {
    /// Whether or not the folder type is most likly realized as virtual mailbox on server side.
    /// See RFC-6154
    var isVirtualMailbox: Bool {
        let virtualMailboxesTypes = [FolderType.all, FolderType.flagged]
        return virtualMailboxesTypes.contains(self)
    }
}
