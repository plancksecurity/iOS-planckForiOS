//
//  FolderViewModel.swift
//  pEpForiOS
//
//  Created by Xavier Algarra on 20/02/17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel

public class FolderCellViewModel {
    let folder: Folder
    let level : Int

    public var icon: UIImage {
        return self.folder.folderType.getIcon()
    }

    public var title : String {
        return self.name
    }

    public var image : UIImage? {
        var name = ""
        switch folder.folderType {
        case .inbox:
            name = "folders-icon-inbox"
            break
        case .archive:
            name = "folders-icon-archive"
            break
        case .drafts:
            name = "folders-icon-draft"
            break
        case .flagged:
            name = "folders-icon-vip"
            break
        case .sent:
            name = "folders-icon-sent"
            break
        case .spam:
            name = "folders-icon-junk"
            break
        case .trash:
            name = "folders-icon-trash"
        default:
            name = "folders-icon-folder"
        }
        return UIImage(named: name)
    }

    private var name: String {
        return self.folder.localizedName
    }

    var leftPadding: Int {
        return level
    }

    public var isSelectable: Bool {
        if folder is UnifiedInbox {
            return true
        } else if folder.isLocalFolder {
            return true
        }
        return folder.selectable
    }

    public init(folder: Folder, level: Int) {
        self.folder = folder
        self.level = level
    }
}
