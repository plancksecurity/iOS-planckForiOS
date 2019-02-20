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
            Logger.frontendLogger.errorAndCrash("No account selected")
            return
        }
        for folder in ac.rootFolders {
            items.append(FolderCellViewModel(folder: folder, level: 0))
            childFolder(root: folder, level: 1)
        }
    }

    private func childFolder(root folder: Folder, level: Int) {
        for subFolder in folder.subFolders() {
            items.append(FolderCellViewModel(folder: subFolder, level: level))
            childFolder(root: subFolder, level: level + 1)
        }
    }

    func getImage(callback: @escaping (UIImage?)-> Void) {
        guard let ac = account else {
            Logger.frontendLogger.errorAndCrash("No account selected")
            return
        }
        if let cachedContactImage = contactImageTool.cachedIdentityImage(for: ac.user) {
            callback(cachedContactImage)
        } else {
            DispatchQueue.global().async {
                let contactImage = self.contactImageTool.identityImage(for: ac.user)
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

    public func collapse() {
        self.collapsed = !self.collapsed
        if !collapsed {
            items = help
            help = [FolderCellViewModel]()
        } else {
            help = items
            items = [FolderCellViewModel]()
        }
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
