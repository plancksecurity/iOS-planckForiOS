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
    private var help = [FolderCellViewModel]()
    let contactImageTool = IdentityImageTool()

    public init(account acc: Account?, Unified: Bool) {
        if Unified {
            let folder = UnifiedInbox()
            hidden = true
            items.append(FolderCellViewModel(folder: folder, level: 0))
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
        let sorted = Array<Any>.sort(foldersToSort: ac.rootFolders)
        for folder in sorted {
            items.append(FolderCellViewModel(folder: folder, level: 0))
            let level = folder.folderType == .inbox ? 0 : 1
            calculateChildFolder(root: folder, level: level)
        }
    }

    private func calculateChildFolder(root folder: Folder, level: Int) {
        let sorted = Array<Any>.sort(foldersToSort: folder.subFolders())
        for subFolder in sorted {
            items.append(FolderCellViewModel(folder: subFolder, level: level))
            calculateChildFolder(root: subFolder, level: level + 1)
        }
    }

    func getImage(callback: @escaping (UIImage?)-> Void) {
        guard let ac = account else {
            Log.shared.errorAndCrash("No account selected")
            return
        }
        let userKey = IdentityImageTool.IdentityKey(identity: ac.user)
        if let cachedContactImage = contactImageTool.cachedIdentityImage(for: userKey) {
            callback(cachedContactImage)
        } else {
            DispatchQueue.global(qos: .userInitiated) .async {
                let contactImage = self.contactImageTool.identityImage(for: userKey)
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

    var count : Int {
        return self.items.count
    }
}

