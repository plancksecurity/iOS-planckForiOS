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

    var accounts = [AccountsSettingsCellViewModel]()
    var settings = [AccountsSettingsCellViewModel]()
    var sectionsViewModel = [AccountsSettingsSectionViewModel]()

    func indexIsValid(section: Int, cell: Int) -> Bool {
        switch section {
        case 0:
            return cell >= 0 && cell <= accounts.count
        case 1:
            return cell >= 0 && cell <= settings.count
        default:
            return false
        }
    }

    func sectionIsValid(section: Int) -> Bool {
        return section >= 0 && section <= sectionsViewModel.count
    }

    subscript(section: Int, cell: Int) -> AccountsSettingsCellViewModel? {
        get {
            assert(sectionIsValid(section: section), "Section index out of range")
            assert(indexIsValid(section: section, cell: cell), "Cell index out of range")
            switch section {
            case 0:
                return accounts[cell]
            case 1:
                return settings[cell]
            default:
                return nil
            }
        }
    }

    subscript(section: Int) -> AccountsSettingsSectionViewModel? {
        get {
            assert(sectionIsValid(section: section), "Section out of range")
            return sectionsViewModel[section]
        }
    }

}

