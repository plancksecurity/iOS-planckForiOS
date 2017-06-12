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

    func generateSections() {
        sections.append(AccountsSettingsSectionViewModel(type: .accounts))
        sections.append(AccountsSettingsSectionViewModel(type: .settings))
    }

    func sectionIsValid(section: Int) -> Bool {
        return section >= 0 && section <= sections.count
    }

    func delete(section: Int, cell: Int) {
        if section == 0 {
            sections[section].delete(cell: cell)
        }
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

