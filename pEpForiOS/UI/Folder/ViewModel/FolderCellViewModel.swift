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
    
    public func hasSubfolders() -> Bool {
        guard let folder = folder as? Folder else {
            // UnifiedInbox implements DisplayableFolderProtocol but is not a Folder
            guard self.folder is UnifiedInbox else {
                Log.shared.errorAndCrash("Not a folder or UnifiedInbox.")
                return false
            }
            return false
        }
        return folder.subFolders().count > 0
    }

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

    public func shouldHideSeparator() -> Bool {
        guard let folder = folder as? Folder else {
            //If is not a folder but a UnifiedInbox is valid
            return self.folder is UnifiedInbox
        }
        return folder.folderType == .outbox
    }

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
        guard let lhsFolder = lhs.folder as? Folder, let rhsFolder = rhs.folder as? Folder else {
            guard let left = lhs.folder as? UnifiedInbox, let right = rhs.folder as? UnifiedInbox else {
                Log.shared.info("One is Unified Inbox the other is not")
                return false
            }
            return left.hashValue == right.hashValue
        }
        return lhsFolder.account.hashValue == rhsFolder.account.hashValue
    }
}
