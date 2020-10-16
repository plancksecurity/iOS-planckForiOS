//
//  Folder+LocalizedName.swift
//  pEp
//
//  Created by Xavier Algarra on 02/04/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel

extension Folder {

    public static func localizedName(realName: String) -> String {
        let validInboxNameVariations = [ "INBOX", "Inbox", "inbox"]

        switch realName {
        case let tmp where  validInboxNameVariations.contains(tmp):
            return NSLocalizedString("Inbox", comment: "Name of INBOX mailbox (of one account)")
        case FolderType.outbox.folderName():
            return NSLocalizedString("Outbox",
                                     comment:
                "Name of outbox (showing messages to send")
        default:
            return realName
        }
    }

}
