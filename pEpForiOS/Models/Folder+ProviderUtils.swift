//
//  Folder+ProviderUtils.swift
//  pEp
//
//  Created by Andreas Buff on 08.02.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel

/*
 Somehow nasty but required provider specific rules.
 */

extension Folder { //BUFF:
    
    /// Whether or not the default destructive action is "archive" instead of "delete".
    var defaultDestructiveActionIsArchive: Bool {
        // Currently Gmail is the only known and considered provider.
        // Gmail:
        // The only folder that should provide "trash" action (not "archive") is the Trash folder
        return address.isGmailAddress && folderType != .trash
    }
}

