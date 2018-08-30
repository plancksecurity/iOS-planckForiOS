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
        case .outbox:
            imageName = "folders-icon-outbox"
        case .spam:
            imageName = "folders-icon-junk"
        case .all, .flagged, .outbox:
            // No icon defined in design. Use normal folder icon as fallback.
            imageName = "folders-icon-folder"
        }
        guard let name = imageName, let image = UIImage(named: name) else {
            return UIImage()
        }
        return image
    }
}
