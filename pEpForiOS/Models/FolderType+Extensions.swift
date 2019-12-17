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

    public static let displayOrder = [FolderType.inbox, .drafts, .sent, .spam, .trash, .all, .flagged, .archive, .normal, .outbox]

    func getIcon() -> UIImage {
        var imageName: String?
        switch self {
        case .normal, .pEpSync:
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
        case .outbox:
            imageName = "folders-icon-outbox"
        case .all, .flagged:
            // No icon defined in design. Use normal folder icon as fallback.
            imageName = "folders-icon-folder"
        }
        guard let name = imageName, let image = UIImage(named: name) else {
            return UIImage()
        }
        return image
    }
}
