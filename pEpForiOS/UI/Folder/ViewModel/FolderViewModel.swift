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
    var items: [FolderSectionViewModel]

    public init(withFordersIn accounts: [Account]? = nil) {
        items = [FolderSectionViewModel]()
        let accountsToUse: [Account]
        if let safeAccounts = accounts {
            accountsToUse = safeAccounts
        } else {
            accountsToUse = Account.all()
        }
        generateSections(accounts: accountsToUse)
    }

    func generateSections(accounts: [Account]) {
        for acc in accounts {
            items.append(FolderSectionViewModel(account: acc))
        }
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
