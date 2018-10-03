//
//  SettingsViewModel.swift
//  pEpForiOS
//
//  Created by Xavier Algarra on 08/06/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel

class SettingsViewModel {
    var sections = [SettingsSectionViewModel]()

    init() {
        generateSections()
    }

    private func generateSections() {
        sections.append(SettingsSectionViewModel(type: .accounts))
        sections.append(SettingsSectionViewModel(type: .globalSettings))
        sections.append(SettingsSectionViewModel(type: .pgpCompatibilitySettings))
    }

    private func sectionIsValid(section: Int) -> Bool {
        return section >= 0 && section < sections.count
    }

    func delete(section: Int, cell: Int) {
        let accountsSection = 0
        if section == accountsSection {
            sections[section].delete(cell: cell)
        }
    }

    func rowType(for indexPath: IndexPath) -> SettingsCellViewModel.SettingType? {
        guard let model = self[indexPath.section][indexPath.row] as?
            ComplexSettingCellViewModelProtocol else {
            return nil
        }
        return model.type
    }

    func noAccounts() -> Bool {
        return Account.all().count <= 0
    }

    var count: Int {
        get {
            return sections.count
        }
    }

    subscript(section: Int) -> SettingsSectionViewModel {
        get {
            assert(sectionIsValid(section: section), "Section out of range")
            return sections[section]
        }
    }
}
