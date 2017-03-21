//
//  FolderViewModel.swift
//  pEpForiOS
//
//  Created by Xavier Algarra on 20/02/17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel

public class FolderSectionViewModel: SectionWithText {

    public var unreadMessages: String
    public var arrow : String
    public var collapsed: Bool

    private var account: Account
    private var items: [FolderCellViewModel]
    private var help :[FolderCellViewModel]


    public init(account acc: Account) {
        self.account = acc
        self.collapsed = false
        items = [FolderCellViewModel]()
        help = [FolderCellViewModel]()
        unreadMessages = "0"
        arrow = ">"
        collapsed = false
        generateCells()
    }

    private func generateCells() {
        for folder in account.rootFolders {
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

    public var title: String {
        return account.user.address
    }

    public func onCollapse(collapsed: Bool) {

        if self.collapsed {
            items = help
            help = [FolderCellViewModel]()
        } else {
            self.collapsed = true
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
