//
//  UnifiedInbox.swift
//  pEp
//
//  Created by Martin Brude on 30/07/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation

#if EXT_SHARE
import MessageModelForAppExtensions
#else
import MessageModel
#endif

public class UnifiedInbox : UnifiedFolderBase {
    public override var agregatedFolderType: FolderType? {
        return FolderType.inbox
    }
    public override var name: String {
        return NSLocalizedString("Inbox (all)", comment: "Unified Inbox Folder name")
    }
}
