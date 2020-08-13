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
    public var collapsed = false
    private var account: Account?
    public var hidden = false
    private var items = [FolderCellViewModel]()
    private let unifiedFolders = [UnifiedInbox(), UnifiedDraft(), UnifiedSent(), UnifiedTrash()]

    private var help = [FolderCellViewModel]()
    let identityImageTool = IdentityImageTool()

    public init(account acc: Account?, Unified: Bool) {
        if Unified {
            hidden = true
            unifiedFolders.forEach { (unifiedFolder) in
                items.append(FolderCellViewModel(folder: unifiedFolder, level: 0))
            }
        }
        if let ac = acc {
            self.account = ac
            generateAccountCells()
        }
    }

    private func generateAccountCells() {
        guard let ac = account else {
            Log.shared.errorAndCrash("No account selected")
            return
        }
        let sorted = ac.rootFolders.sorted()
        for folder in sorted {
            items.append(FolderCellViewModel(folder: folder, level: 0))
            let level = folder.folderType == .inbox ? 0 : 1
            calculateChildFolder(root: folder, level: level)
        }
    }

    private func calculateChildFolder(root folder: Folder, level: Int) {
        let sorted = folder.subFolders().sorted()
        for subFolder in sorted {
            items.append(FolderCellViewModel(folder: subFolder, level: level))
            calculateChildFolder(root: subFolder, level: level + 1)
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

    /// - Returns: Returns the first Folder Cell View Model which folder is an Inbox
    public func firstInbox() -> FolderCellViewModel  {
        guard let fcvm = items.first(where: {$0.isFolder(of: .inbox)}) else {
            Log.shared.errorAndCrash("Inbox not found")
            return FolderCellViewModel(folder: items[0] as! DisplayableFolderProtocol, level: 0)
        }
        return fcvm
    }
}
