//
//  FolderType+NetworkSync.swift
//  pEp
//
//  Created by Andreas Buff on 20.02.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel

extension FolderType {
    var shouldBeSyncedWithServer: Bool {
        switch self {
        case .all: fallthrough
        case .archive: fallthrough
        case .drafts: fallthrough
        case .flagged: fallthrough
        case .inbox: fallthrough
        case .normal: fallthrough
        case .sent: fallthrough
        case .spam:
            return true
        case .trash:
            return AppSettings().shouldSyncImapTrashWithServer
        }
    }
}
