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
    var indentationLevel: Int {
        let subLevel = isSubfolder() ? 1 : 0
        return level + subLevel
    }
    private var requiredFolderTypes : [FolderType] {
        return [.drafts, .sent, .spam, .trash, .outbox]
    }

    public var title : String {
        return name
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

    var padding: CGFloat {
        return DeviceUtils.isIphone5 ? 16.0 : 25.0
    }

    public var isSelectable: Bool {
        return folder.isSelectable
    }

    public var numUnreadMails : Int {
        if let f = folder as? VirtualFolderProtocol {
            return f.countUnread
        } else if let f = folder as? Folder {
            return f.countUnread
        } else {
            Log.shared.errorAndCrash("Can't recognize Folder")
            return 0
        }
    }

    public var isExpand = true
    public var isHidden = false

    public init(folder: DisplayableFolderProtocol, level: Int) {
        self.folder = folder
        self.level = level
    }

    public var shouldRotateChevron : Bool {
        return isExpand && hasSubfolders() && isChevronEnabled
    }

    public var isChevronEnabled: Bool {
        return hasSubfolders() && !(folder is UnifiedInbox)
    }

    /// Indicates if the current folder cell view model has subfolders.
    /// - Returns: True if it has.
    public func hasSubfolders() -> Bool {
        guard let folder = folder as? Folder else {
            // UnifiedInbox implements DisplayableFolderProtocol but is not a Folder
            guard self.folder is UnifiedFolderBase else {
                Log.shared.errorAndCrash("Not a folder or UnifiedInbox.")
                return false
            }
            return false
        }
        return folder.subFolders().count > 0
    }

    /// Indicates if the FolderCellViewModel passed by parameter is its children
    /// - Parameter fcvm: The possible children of the current FolderCellViewModel
    /// - Returns: True if its child or decendent. 
    public func isParentOf(fcvm: FolderCellViewModel) -> Bool {
        if let childFolder = fcvm.folder as? Folder, let parentFolder = folder as? Folder {
            if childFolder.account.accountType != VerifiableAccount.AccountType.gmail {
                if requiredFolderTypes.contains(childFolder.folderType) {
                    return false
                }
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

    /// Indicates if the folder of the type passed by parameter.
    /// - Parameter type: The Folder type
    /// - Returns: True if it is a folder of that type
    public func isFolder(of type: FolderType) -> Bool {
        if let f = folder as? Folder {
            return f.folderType == type
        }
        return false
    }

    /// Indicates if the separator should be hidden.
    /// - Returns: True to hide the separator.
    public func shouldHideSeparator() -> Bool {
        guard let folder = folder as? Folder else {
            //If is not a folder but a Unified folder is valid
            return self.folder is UnifiedTrash
        }
        return folder.folderType == .outbox
    }

    /// Indicates if the current folder cell view model is a subfolder.
    /// - Returns: True if it is.
    public func isSubfolder() -> Bool {
        guard let folder = folder as? Folder else {
            //If is not a folder, it's a UnifiedInbox
            return false
        }
        return folder.folderType == .normal && folder.folderType != .outbox && folder.parent != nil

    }
}
extension FolderCellViewModel : Equatable {

    public static func == (lhs: FolderCellViewModel, rhs: FolderCellViewModel) -> Bool {
        /// Both are Folders
        if let lhsFolder = lhs.folder as? Folder, let rhsFolder = rhs.folder as? Folder {
            return lhsFolder == rhsFolder
        }
        /// Both are UnifiedInbox
        if let left = lhs.folder as? UnifiedInbox, let right = rhs.folder as? UnifiedInbox {
            return left == right
        }
        //One is Unified Inbox the other is not
        return false
    }
}
