//
//  SettingsKeyImportSelectAccountViewModel.swift
//  pEp
//
//  Created by Hussein on 03/07/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel

class SettingsKeyImportSelectAccountViewModel {
    var items : [KeyImportAccountCellViewModel]
    let keyImportService: KeyImportServiceProtocol

    init (keyImportService: KeyImportServiceProtocol) {
        items = []
        self.keyImportService = keyImportService

        generateCells()

    }
    
    func generateCells() {
        Account.all().forEach { (account) in
            self.items.append(KeyImportAccountCellViewModel(account: account,
                                                            keyImportService: keyImportService))
        }
    }
    
    subscript(index: Int) -> KeyImportAccountCell {
        get {
            return self.items[index]
        }
    }
    
    var count: Int {
        return self.items.count
    }

}
