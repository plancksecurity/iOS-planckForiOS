//
//  MoveToFolderViewModel.swift
//  pEp
//
//  Created by Xavier Algarra on 14/06/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel

class MoveToAccountViewModel {

    //var delegate: MoveToFolderDelegate
    var accounts = Account.all()
    var items : [MoveToAccountCellViewModel]
    var messages: [Message]
    /// We do not allow to move messages to those folders.
    /// Drafts: It does not make sense to move a message e.g. from Inbox to Drafts.
    ///         Who is supposed to be the sender (From) when opening the draft?
    /// Sent:   It does not make sense to move a message e.g. from Inbox to Sent.
    ///         Also Sent needs special handling (encrypt for self or such).
    let folderTypesNotAllowedToMoveTo = [FolderType.drafts, .sent]

    init(messages: [Message]) {
        self.messages = messages
        items = []
        for acc in accounts {
            items.append(MoveToAccountCellViewModel(account: acc))
        }
    }

    subscript(index: Int) -> MoveToAccountCellViewModel {
        get {
            return self.items[index]
        }
    }

    var count : Int {
        return self.items.count
    }
}

class MoveToAccountCellViewModel {

    var account: Account
    var title: String

    init(account: Account) {
        self.account = account
        self.title = account.user.address
    }

    public func viewModel() -> moveToFolderViewModel {
        return moveToFolderViewModel(account: account)
    }
}

class moveToFolderViewModel {
    var items : [moveToFolderCellViewModel]
    var acc : Account
    init(account: Account) {
        items = []
        self.acc = account
        generateAccountCells()
    }

    private func generateAccountCells() {
        for folder in acc.rootFolders {
            items.append(moveToFolderCellViewModel(folder: folder, level: 0))
            childFolder(root: folder, level: 1)
        }
    }

    private func childFolder(root folder: Folder, level: Int) {
        for subFolder in folder.subFolders() {
            items.append(moveToFolderCellViewModel(folder: subFolder, level: level))
            childFolder(root: subFolder, level: level + 1)
        }
    }

    subscript(index: Int) -> moveToFolderCellViewModel {
        get {
            return self.items[index]
        }
    }

    var count : Int {
        return self.items.count
    }
}

class moveToFolderCellViewModel {
    var folder: Folder
    var title: String
    var indentationLevel: Int

    init(folder: Folder, level: Int) {
        self.folder = folder
        self.title = folder.realName
        self.indentationLevel = level
    }
}
