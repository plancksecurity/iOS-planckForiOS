//
//  SettingsViewModel.swift
//  pEpForiOS
//
//  Created by Xavier Algarra on 08/06/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel

protocol SettingsViewModelDelegate: class {
    func showExtraKeyEditabilityStateChangeAlert(newValue: String)
}

final class SettingsViewModel {
    weak var delegate: SettingsViewModelDelegate?
    var sections = [SettingsSectionViewModel]()
    private let keySyncDeviceGroupService: KeySyncDeviceGroupServiceProtocol?
    private let messageModelService: MessageModelServiceProtocol

    init(_ messageModelService: MessageModelServiceProtocol,
         _ keySyncDeviceGroupService: KeySyncDeviceGroupServiceProtocol = KeySyncDeviceGroupService(),
         delegate: SettingsViewModelDelegate? = nil) {
        self.keySyncDeviceGroupService = keySyncDeviceGroupService
        self.messageModelService = messageModelService
        self.delegate = delegate
        generateSections()
    }

    private func generateSections() {
        sections.append(SettingsSectionViewModel(type: .accounts))
        sections.append(SettingsSectionViewModel(type: .globalSettings))
        sections.append(SettingsSectionViewModel(type: .pgpCompatibilitySettings))
        sections.append(SettingsSectionViewModel(type: .keySync,
                                                 messageModelService: messageModelService,
                                                 keySyncDeviceGroupService: keySyncDeviceGroupService))
        sections.append(SettingsSectionViewModel(type: .companyFeatures))
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
            removeLeaveDeviceGroupCell()
        } catch {
            Log.shared.errorAndCrash("%@", error.localizedDescription)
            return error
        }
        return nil
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

    private func removeLeaveDeviceGroupCell() {
        for section in sections {
            guard section.type == .keySync else {
                continue
            }
            section.removeLeaveDeviceGroupCell()
        }
    }
}

// MARK: - ExtryKeysEditability

extension SettingsViewModel {

    func handleExtryKeysEditabilityGestureTriggered() {
        let newValue = !AppSettings.extraKeysEditable
        AppSettings.extraKeysEditable = newValue
        delegate?.showExtraKeyEditabilityStateChangeAlert(newValue: newValue ? "ON" : "OFF")
    }
}
