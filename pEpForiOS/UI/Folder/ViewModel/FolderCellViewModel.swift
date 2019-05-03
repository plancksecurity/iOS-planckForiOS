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
    let folder: DisplayableFolderProtocol
    let level : Int

    public var title : String {
        return self.name
    }

    public var image : UIImage? {
        if let f = folder as? VirtualFolderProtocol {
            return f.agregatedFolderType?.getIcon()
        } else if let f = folder as? Folder {
            return f.folderType.getIcon()
        } else {
            return nil
        }
    }

    private var name: String {
        return Folder.localizedName(realName: self.folder.title)
    }

    var leftPadding: Int {
        return level
    }

    public var isSelectable: Bool {
        if let f = folder as? Folder {
            if f.isLocalFolder {
                return true
            }
            return f.selectable
        } else if folder is VirtualFolderProtocol{
            return true
        }
        return false
    }

    public init(folder: DisplayableFolderProtocol, level: Int) {
        self.folder = folder
        self.level = level
    }
}

