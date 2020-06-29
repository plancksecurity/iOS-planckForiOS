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
    //TODO: make it private
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
        return folder.isSelectable
    }

    public var isExpand = true

    public init(folder: DisplayableFolderProtocol, level: Int) {
        self.folder = folder
        self.level = level
    }

    public func hasSubfolders() -> Bool {
        guard let folder = folder as? Folder else {
            return false
        }
        return folder.subFolders().count > 0
    }

    public func isParentOf(fcvm: FolderCellViewModel) -> Bool {
        if let childFolder = fcvm.folder as? Folder, let parentFolder = folder as? Folder {
            if childFolder.parent == parentFolder {
                return true
            }

            var parent = childFolder.parent
            while parent != nil {
                if parent?.parent == parentFolder {
                    return true
                } else {
                    parent = parent?.parent
                }
            }
        }
        return false
    }

    public func shouldHideSeparator() -> Bool {
        if let f = folder as? Folder {
            return f.folderType == .outbox
        }
        return folder is UnifiedInbox
    }
    
}

