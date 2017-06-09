//
//  AccountSectionViewModel.swift
//  pEpForiOS
//
//  Created by Xavier Algarra on 08/06/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel

public enum SettingsSection {
    case accounts
    case settings
}

public enum SettingsCell {
    case showLog
    case organizedByThread
}

public class AccountsSettingsSectionViewModel {

    var cells = [AccountsSettingsCellViewModel]()
    var title: String?
    
    init(type: SettingsSection) {
        switch type {
        case .accounts:
            generateAccountCells()
            title = NSLocalizedString("Accounts", comment: "Table header")
        case .settings:
            generateSettingsCells()
            title = NSLocalizedString("Settings", comment: "Table header")
        }
    }

    func generateAccountCells() {
        Account.all().forEach { (acc) in
            self.cells.append(AccountsSettingsCellViewModel(account: acc))
        }
    }

    func generateSettingsCells() {
        self.cells.append(AccountsSettingsCellViewModel(type: .showLog))
        self.cells.append(AccountsSettingsCellViewModel(type: .organizedByThread))
    }

    func cellIsValid(cell: Int) -> Bool {
        return cell >= 0 && cell <= cells.count
    }

    var count: Int {
        get {
            return cells.count
        }
    }

    subscript(cell: Int) -> AccountsSettingsCellViewModel {
        get {
            assert(cellIsValid(cell: cell), "Cell out of range")
            return cells[cell]
        }
    }

}
