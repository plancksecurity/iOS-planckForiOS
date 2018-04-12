//
//  AccountSectionViewModel.swift
//  pEpForiOS
//
//  Created by Xavier Algarra on 08/06/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel

public class AccountsSettingsSectionViewModel {

    public enum SectionType {
        case accounts
        case glogalSettings
        case pgpCompatibilitySettings
    }

    var cells = [AccountsSettingsCellViewModel]()
    var title: String?
    let type: SectionType
    
    init(type: SectionType) {
        self.type = type
        switch type {
        case .accounts:
            generateAccountCells()
            title = NSLocalizedString("Accounts", comment: "Tableview section  header")
        case .glogalSettings:
            generateGlobalSettingsCells()
            title = NSLocalizedString("Global Settings", comment: "Tableview section header")
        case .pgpCompatibilitySettings:
            generatePgpCompatibilitySettingsCells()
            title = NSLocalizedString("PGP Compatibility", comment: "Tableview section header")
        }
    }

    func generateAccountCells() {
        Account.all().forEach { (acc) in
            self.cells.append(AccountsSettingsCellViewModel(account: acc))
        }
    }

    func generateGlobalSettingsCells() {
        self.cells.append(AccountsSettingsCellViewModel(type: .syncTrash))
        self.cells.append(AccountsSettingsCellViewModel(type: .organizedByThread))
        self.cells.append(AccountsSettingsCellViewModel(type: .credits))
        self.cells.append(AccountsSettingsCellViewModel(type: .showLog))
    }

    func generatePgpCompatibilitySettingsCells() {
        self.cells.append(AccountsSettingsCellViewModel(type: .unecryptedSubject))
    }

    func delete(cell: Int) {
        cells[cell].delete()
        cells.remove(at: cell)
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
