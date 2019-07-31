//
//  SettingsViewModel.swift
//  pEpForiOS
//
//  Created by Xavier Algarra on 08/06/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel

final class SettingsViewModel {
    var sections = [SettingsSectionViewModel]()
    private let keySyncDeviceGroupService: KeySyncDeviceGroupServiceProtocol?
    private let messageModelService: MessageModelServiceProtocol

    init(_ messageModelService: MessageModelServiceProtocol,
         _ keySyncDeviceGroupService: KeySyncDeviceGroupServiceProtocol = KeySyncDeviceGroupService()) {
        self.keySyncDeviceGroupService = keySyncDeviceGroupService
        self.messageModelService = messageModelService
        generateSections()
    }

    private func generateSections() {
        sections.append(SettingsSectionViewModel(type: .accounts))
        sections.append(SettingsSectionViewModel(type: .globalSettings))
        sections.append(SettingsSectionViewModel(type: .pgpCompatibilitySettings))
        sections.append(SettingsSectionViewModel(type: .keySync,
                                                 messageModelService: messageModelService,
                                                 keySyncDeviceGroupService: keySyncDeviceGroupService))
    }

    func delete(section: Int, cell: Int) {
        let accountsSection = 0
        if section == accountsSection {
            sections[section].delete(cell: cell)
        }
    }

    func leaveDeviceGroupPressed() -> Error? {
        guard let keySyncDeviceGroupService = keySyncDeviceGroupService else {
            let error = SettingsInternalError.nilKeySyncDeviceGroupService
            Log.shared.errorAndCrash("%@", error.localizedDescription)
            return error
        }
        do {
            try keySyncDeviceGroupService.leaveDeviceGroup()
        } catch {
            Log.shared.errorAndCrash("%@", error.localizedDescription)
            return error
        }
        return nil
    }

    func removeLeaveDeviceGroupCell() {
        for section in sections {
            guard section.type == .keySync else {
                continue
            }
            section.removeLeaveDeviceGroupCell()
        }
    }

    //temporal stub
    func canBeShown(Message: Message? ) -> Bool {
        return false
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

// MARK: - Private
extension SettingsViewModel {
    private func sectionIsValid(section: Int) -> Bool {
        return section >= 0 && section < sections.count
    }
}
