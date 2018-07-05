//
//  AccountsSettingsViewModel.swift
//  pEpForiOS
//
//  Created by Xavier Algarra on 08/06/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel

class AccountsSettingsViewModel {
    var sections = [AccountsSettingsSectionViewModel]()

    init() {
        generateSections()
    }

    private func generateSections() {
        sections.append(AccountsSettingsSectionViewModel(type: .accounts))
        sections.append(AccountsSettingsSectionViewModel(type: .glogalSettings))
        sections.append(AccountsSettingsSectionViewModel(type: .pgpCompatibilitySettings))
    }

    private func sectionIsValid(section: Int) -> Bool {
        return section >= 0 && section <= sections.count
    }

    func delete(section: Int, cell: Int) {
        let accountsSection = 0
        if section == accountsSection {
            sections[section].delete(cell: cell)
        }
    }

    func rowType(for indexPath: IndexPath) -> SettingType {
        return self[indexPath.section][indexPath.row].type
    }

    func noAccounts() -> Bool {
        return Account.all().count <= 0
    }

    var count: Int {
        get {
            return sections.count
        }
    }

    subscript(section: Int) -> AccountsSettingsSectionViewModel {
        get {
            assert(sectionIsValid(section: section), "Section out of range")
            return sections[section]
        }
    }
}
