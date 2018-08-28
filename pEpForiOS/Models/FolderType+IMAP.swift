//
//  FolderType+IMAP.swift
//  pEp
//
//  Created by Andreas Buff on 06.02.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel

extension FolderType {
    /// Folder of those types mirror a remote IMAP folder and have to be synced.
    static let typesSyncedWithImapServer = [FolderType.inbox,
                                            .normal,
                                            .sent,
                                            .drafts,
                                            .trash,
                                            .spam,
                                            .archive,
                                            .all, .flagged] //IOS-729: sure about .all and .flagged?

    /// Flags that should be used when appending mails to a folder of this type.
    ///
    /// - Returns:  If flags are defined for this type:: the flags.
    ///             nil otherwize
    func defaultAppendImapFlags() -> Message.ImapFlags? {
        switch self {
        case .sent:
            let result = Message.ImapFlags()
            result.seen = true
            return result
        case .archive, .drafts, .inbox, .normal, .trash, .spam, .all, .flagged, .outbox:
            break
        }
        return nil
    }
}
