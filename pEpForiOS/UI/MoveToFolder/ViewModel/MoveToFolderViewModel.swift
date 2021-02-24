//
//  MoveToFolderViewModel.swift
//  pEp
//
//  Created by Xavier Algarra on 14/06/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation
import UIKit

#if EXT_SHARE
import MessageModelForAppExtensions
#else
import MessageModel
#endif

#if EXT_SHARE
import PEPIOSToolboxForAppExtensions
#else
import pEpIOSToolbox
#endif

let folderTypesNotAllowedToMoveTo = [FolderType.drafts, .sent, .outbox]

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
    var items : [MoveToFolderCellViewModel]
    var acc : Account
    var messages: [Message]

    init(account: Account, messages: [Message]) {
        items = []
        self.acc = account
        self.messages = messages
        generateFolderCells()
    }

    private func generateFolderCells() {
        let sorted = acc.rootFolders.sorted()
        for folder in sorted {
            items.append(MoveToFolderCellViewModel(folder: folder, level: 0))
            childFolder(root: folder, level: 1)
        }
    }

    private func childFolder(root folder: Folder, level: Int) {
        let sorted = folder.subFolders().sorted()
        for subFolder in sorted {
            items.append(MoveToFolderCellViewModel(folder: subFolder, level: level))
            childFolder(root: subFolder, level: level + 1)
        }
    }

    @discardableResult
    func moveMessagesTo(index: Int) -> Bool {
        if !(index >= 0 && index < items.count) {
            Log.shared.error("Index out of bounds")
            return false
        }
        let targetFolder = items[index].folder
        var result = false
        let msgs = messages.filter { $0.parent != targetFolder }
        if !msgs.isEmpty {
            result = true
            Message.move(messages: msgs, to: targetFolder)
        }
        return result
    }

    subscript(index: Int) -> MoveToFolderCellViewModel {
        get {
            return self.items[index]
        }
    }

    var count : Int {
        return self.items.count
    }
}

class MoveToFolderCellViewModel {
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
