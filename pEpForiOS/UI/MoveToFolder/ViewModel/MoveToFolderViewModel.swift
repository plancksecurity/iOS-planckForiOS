//
//  MoveToFolderViewModel.swift
//  pEp
//
//  Created by Xavier Algarra on 14/06/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel

let folderTypesNotAllowedToMoveTo = [FolderType.drafts, .sent]

class MoveToAccountViewModel {

    var accounts = Account.all()
    var items : [MoveToAccountCellViewModel]
    /// We do not allow to move messages to those folders.
    /// Drafts: It does not make sense to move a message e.g. from Inbox to Drafts.
    ///         Who is supposed to be the sender (From) when opening the draft?
    /// Sent:   It does not make sense to move a message e.g. from Inbox to Sent.
    ///         Also Sent needs special handling (encrypt for self or such).
    let folderTypesNotAllowedToMoveTo = [FolderType.drafts, .sent]

    init(messages: [Message]) {
        items = []
        for acc in accounts {
            items.append(MoveToAccountCellViewModel(account: acc, messages: messages))
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
    var messages: [Message]

    init(account: Account, messages: [Message]) {
        self.account = account
        self.title = account.user.address
        self.messages = messages
    }

    public func viewModel() -> MoveToFolderViewModel {
        return MoveToFolderViewModel(account: account, messages: messages)
    }
}

class MoveToFolderViewModel {
    var items : [moveToFolderCellViewModel]
    var acc : Account
    var messages: [Message]
    var delegate : MoveToFolderDelegate?

    init(account: Account, messages: [Message]) {
        items = []
        self.acc = account
        self.messages = messages
        generateFolderCells()
    }

    private func generateFolderCells() {
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

    func moveMessagesTo(index: Int) -> Bool {
        let targetFolder = items[index].folder
        var result = false
        for msg in messages {
            if msg.parent != targetFolder {
                msg.move(to: items[index].folder)
                result = true
            }
        }
        if result {
            delegate?.didmove(messages: messages)
        }
        return result
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
    var icon: UIImage
    var isSelectable : Bool {
        get {
            return folder.selectable && !folderTypesNotAllowedToMoveTo.contains(folder.folderType)
        }
    }

    init(folder: Folder, level: Int) {
        self.folder = folder
        self.title = folder.realName
        self.indentationLevel = level
        self.icon = folder.folderType.getIcon()

    }
}
