//
//  FolderViewModel.swift
//  pEpForiOS
//
//  Created by Xavier Algarra on 20/02/17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel
import pEpIOSToolbox

public class FolderSectionViewModel {

    /// Indicates if the section is collapsed.
    public var isCollapsed : Bool = false

    private var account: Account?

    /// Indicates if the section header should be hidden.
    public var sectionHeaderHidden = false

    private var items = [FolderCellViewModel]()
    private let unifiedFolders = [UnifiedInbox(), UnifiedDraft(), UnifiedSent(), UnifiedTrash()]

    private var help = [FolderCellViewModel]()
    private let identityImageTool = IdentityImageTool()

    public init(account acc: Account?, unified: Bool) {
        if unified {
            sectionHeaderHidden = true
            unifiedFolders.forEach { (unifiedFolder) in
                items.append(FolderCellViewModel(folder: unifiedFolder, level: 0))
            }
        }
        if let ac = acc {
            self.account = ac
            generateAccountCells()

            //MARK: Collapsing State

            if let accountCollapsingState = AppSettings.shared.collapsingState[ac.user.address] {
                let accountMark = ""
                isCollapsed = accountCollapsingState[accountMark] ?? false
            }
        }
    }

    private func generateAccountCells() {
        guard let ac = account else {
            Log.shared.errorAndCrash("No account selected")
            return
        }
        let sorted = ac.rootFolders.sorted()

        for folder in sorted {
            let fcvm = FolderCellViewModel(folder: folder, level: 0)
            items.append(fcvm)
            let level = folder.folderType == .inbox ? 0 : 1
            // Root folder are always isParentExpanded.
            calculateChildFolder(root: folder, level: level)
        }
    }

    private func calculateChildFolder(root folder: Folder, level: Int, isParentCollapsed: Bool = false) {
        let sorted = folder.subFolders().sorted()
        for subFolder in sorted {
            let child = FolderCellViewModel(folder: subFolder, level: level)

            if isParentCollapsed {
                child.isHidden = true
                child.isExpanded = false
            }
            //MARK: Collapsing State
            if let accountCollapsingState = AppSettings.shared.collapsingState[folder.account.user.address] {
                if let isFolderCollapsed = accountCollapsingState[subFolder.name] {
                    child.isExpanded = !isFolderCollapsed
                }
            }
            items.append(child)
            calculateChildFolder(root: subFolder, level: level + 1, isParentCollapsed: !child.isExpanded)
        }
    }

    public func getImage(callback: @escaping (UIImage?)-> Void) {
        guard let ac = account else {
            Log.shared.errorAndCrash("No account selected")
            return
        }
        let userKey = IdentityImageTool.IdentityKey(identity: ac.user)
        if let cachedContactImage = identityImageTool.cachedIdentityImage(for: userKey) {
            callback(cachedContactImage)
        } else {
            DispatchQueue.global(qos: .userInitiated).async {
                let contactImage = self.identityImageTool.identityImage(for: userKey)
                DispatchQueue.main.async {
                    callback(contactImage)
                }
            }
        }
    }

    public var type: String {
        return "Email"
    }

    public var userAddress: String {
        guard let ac = account else {
            return ""
        }
        return ac.user.address
    }

    public var userName: String {
        guard let ac = account, let un = ac.user.userName else {
            return ""
        }
        return un
    }

    subscript(index: Int) -> FolderCellViewModel {
        get {
            return self.items[index]
        }
    }

    /// Returns the FolderCellViewModel from the visible collection.
    /// - Parameter index: The index of the row.
    /// - Returns: The FolderCellViewModel
    func visibleFolderCellViewModel(index: Int) -> FolderCellViewModel {
        return visibleItems[index]
    }

    var count : Int {
        return self.items.count
    }

    /// Number of visible rows.
    var numberOfRows : Int {
        get {
            return visibleItems.count
        }
    }

    private var visibleItems : [FolderCellViewModel] {
        get {
            return items.filter { !$0.isHidden }
        }
    }

    /// Returns the children folder cell view models of a given folder cell view model.
    /// - Parameter item: The FCVM to find its children.
    /// - Returns: The FCMV's children
    public func children(of item: FolderCellViewModel) -> [FolderCellViewModel] {
        return items.filter { item.isParentOf(fcvm: $0) }
    }

    /// Returns the visible children folder cell view models of a given folder cell view model.
    /// - Parameter item: The FCVM to find its children.
    /// - Returns: The visible FCMV's children
    public func visibleChildren(of item: FolderCellViewModel) -> [FolderCellViewModel] {
        return items.filter { item.isParentOf(fcvm: $0) && !$0.isHidden }
    }

    /// Retrives the index o a folder cell view model.
    /// - Parameter item: The vm to get its index.
    /// - Returns: The index if exists, nil if not.
    public func index(of item : FolderCellViewModel) -> Int? {
        return items.firstIndex(of: item)
    }

    /// Retrives the index of a folder cell view model within the visible items.
    /// - Parameter item: The vm to get its index.
    /// - Returns: The index if exists, nil if not.
    public func visibleIndex(of item : FolderCellViewModel) -> Int? {
        return visibleItems.firstIndex(of: item)
    }

    /// - Returns: the first Folder Cell View Model which folder is an Inbox
    public func firstInbox() -> FolderCellViewModel  {
        guard let fcvm = items.first(where: {$0.isFolder(ofType: .inbox)}) else {
            Log.shared.errorAndCrash("Inbox not found")
            return FolderCellViewModel(folder: items[0] as! DisplayableFolderProtocol, level: 0)
        }
        return fcvm
    }
}
