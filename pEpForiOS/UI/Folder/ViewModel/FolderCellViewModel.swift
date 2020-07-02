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


    private var requiredFolders: [String] {
        return ["Drafts", "Sent", "Spam", "Trash", "Outbox"]
    }

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
    public var isHidden = false

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
            if requiredFolders.contains(childFolder.title) {
                return false
            }
            if childFolder.title == "A" {
                return false
            }
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

    public func isSubfolder() -> Bool {
        if let folder = folder as? Folder {
            return folder.folderType == .normal && folder.folderType != .outbox
        }
        return false
    }

    public func children() -> [FolderCellViewModel] {
        return [FolderCellViewModel]()
    }
}


extension FolderCellViewModel : Equatable {
    public static func == (lhs: FolderCellViewModel, rhs: FolderCellViewModel) -> Bool {
        //TODO: check this. 
        return lhs.title == rhs.title && lhs.folder.title == rhs.folder.title
    }
}
