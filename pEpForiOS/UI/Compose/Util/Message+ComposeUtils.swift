//
//  Message+ComposeUtils.swift
//  pEpForiOSTests
//
//  Created by Andreas Buff on 11.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

#if EXT_SHARE
import MessageModelForAppExtensions
#else
import MessageModel
#endif

// MARK: - Message+ComposeUtils

extension Message {
    var isInDraftsOrOutbox: Bool {
        return isDrafts || isOutbox
    }

    private var isDrafts: Bool {
        return self.parent.folderType == .drafts
    }

    private var isOutbox: Bool {
        return self.parent.folderType == .outbox
    }
}
