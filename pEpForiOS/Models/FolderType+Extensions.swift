//
//  FolderType+Extensions.swift
//  pEpForiOS
//
//  Created by Xavier Algarra on 22/02/17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit
import MessageModel

// MARK: - DEFAULT FLAGS

extension FolderType {

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
