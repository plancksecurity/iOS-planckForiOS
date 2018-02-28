//
//  FolderViewModel.swift
//  pEpForiOS
//
//  Created by Xavier Algarra on 20/02/17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel

public class FolderSectionViewModel {
    public var collapsed = false
    private var account: Account
    private var items = [FolderCellViewModel]()
    private var help = [FolderCellViewModel]()
    let contactImageTool = IdentityImageTool()

    public init(account acc: Account) {
        self.account = acc
        generateCells()
    }

    private func generateCells() {
        for folder in account.rootFolders {
            if folder.selectable {
                items.append(FolderCellViewModel(folder: folder, level: 0))
            }

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
        if let cachedContactImage = contactImageTool.cachedIdentityImage(forIdentity: account.user) {
            callback(cachedContactImage)
        } else {
            DispatchQueue.global().async {
                let contactImage = self.contactImageTool.identityImage(for: self.account.user)
                callback(contactImage)
            }
        }
    }

    public var type: String {
        return "Email"
    }

    public var userAddress: String {
        return account.user.address
    }

    public var userName: String {
        guard let un = account.user.userName else {
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
