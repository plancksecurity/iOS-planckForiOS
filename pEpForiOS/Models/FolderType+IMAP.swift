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
}
