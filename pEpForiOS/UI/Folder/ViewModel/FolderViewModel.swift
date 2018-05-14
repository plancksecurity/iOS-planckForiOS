//
//  FolderViewModel.swift
//  pEpForiOS
//
//  Created by Xavier Algarra on 21/03/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel

public class FolderViewModel {

    private var items: [FolderSectionViewModel]

    public init () {
        items = [FolderSectionViewModel]()
        let accounts = Account.all()
        generateSections(accounts: accounts)
    }

    private func generateSections(accounts: [Account]) {
        items.append(FolderSectionViewModel(account: nil, Unified: true))
        for acc in accounts {
            items.append(FolderSectionViewModel(account: acc, Unified: false))
        }
    }

    public func noAccountsExist() -> Bool {
        return Account.all().isEmpty
    }

    subscript(index: Int) -> FolderSectionViewModel {
        get {
            return self.items[index]
        }
    }

    var count: Int {
        return self.items.count
    }
}
