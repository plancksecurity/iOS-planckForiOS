//
//  FolderType+Extensions.swift
//  pEpForiOS
//
//  Created by Xavier Algarra on 22/02/17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit
import MessageModel

// MARK: - ICON

extension FolderType {

    func getIcon() -> UIImage {
        var imageName: String?
        switch self {
        case .normal:
            imageName = "folders-icon-folder"
        case .archive:
            imageName = "folders-icon-archive"
        case .drafts:
            imageName = "folders-icon-draft"
        case .inbox:
            imageName = "folders-icon-inbox"
        case .sent:
           imageName = "folders-icon-sent"
        case .trash:
            imageName = "folders-icon-trash"
        case .spam:
            imageName = "folders-icon-junk"
        case .all, .flagged:
            break
        }
        guard let name = imageName, let image = UIImage(named: name) else {
            return UIImage()
        }
        return image
    }
}

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
        case .archive, .drafts, .inbox, .normal, .trash, .spam, .all, .flagged:
            break
        }
        return nil
    }
}
