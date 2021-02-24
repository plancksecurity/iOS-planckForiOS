//
//  Folder+LocalizedName.swift
//  pEp
//
//  Created by Xavier Algarra on 02/04/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import Foundation

#if EXT_SHARE
import MessageModelForAppExtensions
#else
import MessageModel
#endif

extension Folder {

    public static func localizedName(realName: String) -> String {
        let validInboxNameVariations = [ "INBOX", "Inbox", "inbox"]

        switch realName {
        case let tmp where validInboxNameVariations.contains(tmp):
            return NSLocalizedString("Inbox", comment: "Name of INBOX mailbox (of one account)")
        case FolderType.sent.folderName():
            return NSLocalizedString("Sent",
                                     comment:
                "Name of Sent folder (showing messages to send, of one account)")
        case FolderType.drafts.folderName():
            return NSLocalizedString("Drafts",
                                     comment:
                "Name of Drafts folder (showing draft messages, of one account)")
        case FolderType.trash.folderName():
            return NSLocalizedString("Trash",
                                     comment:
                "Name of Trash folder (showing deleted messages, of one account)")
        case FolderType.archive.folderName():
            return NSLocalizedString("Archive",
                                     comment:
                "Name of Archive folder (showing archived messages, of one account)")
        case FolderType.spam.folderName():
            return NSLocalizedString("Spam",
                                     comment:
                "Name of Spam folder (showing messages marked as spam by the server, of one account)")
        case FolderType.all.folderName():
            return NSLocalizedString("All",
                                     comment:
                "Name of Googles All folder (showing messages in Googles All  of one account)")
        case FolderType.flagged.folderName():
            return NSLocalizedString("Flagged",
                                     comment:
                "Name of Flagged folder (showing messages marked as flagged by the user, of one account)")
        case FolderType.outbox.folderName():
            return NSLocalizedString("Outbox",
                                     comment:
                "Name of outbox (showing messages to send")
        default:
            return realName
        }
    }
}
