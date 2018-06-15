//
//  MoveToFolderViewModel.swift
//  pEp
//
//  Created by Xavier Algarra on 14/06/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel

class MoveToFolderViewMode {

    //var delegate: MoveToFolderDelegate
    var accounts = Account.all()
    var items : [MoveToFolderCellViewModel]
    var messages: [Message]

    init(messages: [Message]) {
        self.messages = messages
        items = []
        for acc in accounts {
            items.append(MoveToFolderCellViewModel(account: acc))
        }
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

    var account: Account
    var title: String

    init(account: Account) {
        self.account = account
        self.title = account.user.address
    }
}
