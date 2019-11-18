//
//  SettingsViewModel.swift
//  pEpForiOS
//
//  Created by Xavier Algarra on 08/06/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel
import PEPObjCAdapterFramework

protocol SettingsViewModelDelegate: class {
    func showExtraKeyEditabilityStateChangeAlert(newValue: String)
    func showLoadingView()
    func hideLoadingView()
}

final class SettingsViewModel {
    weak var delegate: SettingsViewModelDelegate?
    var sections = [SettingsSectionViewModel]()

    init(delegate: SettingsViewModelDelegate? = nil) {
        self.delegate = delegate
        generateSections()
    }

    private func generateSections() {
        sections.append(SettingsSectionViewModel(type: .accounts))
        sections.append(SettingsSectionViewModel(type: .globalSettings))
        sections.append(SettingsSectionViewModel(type: .keySync))
        sections.append(SettingsSectionViewModel(type: .contacts))
        sections.append(SettingsSectionViewModel(type: .companyFeatures))
    }

    func delete(section: Int, cell: Int) {
        let accountsSection = 0
        if section == accountsSection {
            sections[section].delete(cell: cell)
        }
    }

    func leaveDeviceGroupPressed() -> Error? {
        do {
            try KeySyncDeviceGroupUtil.leaveDeviceGroup()
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

    func pEpSyncSection() -> Int? {
        return sections.firstIndex {
            $0.type == .keySync
        }
    }

    func handleResetAllIdentities() {
        delegate?.showLoadingView()
        Account.resetAllOwnKeys() { [weak self] result in
            switch result {
            case .success():
                self?.delegate?.hideLoadingView()
            case .failure(let error):
                self?.delegate?.hideLoadingView()
                Log.shared.errorAndCrash("Fail to reset all identities, with error %@ ",
                                         error.localizedDescription)
            }
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
        let newValue = !AppSettings.shared.extraKeysEditable
        AppSettings.shared.extraKeysEditable = newValue
        delegate?.showExtraKeyEditabilityStateChangeAlert(newValue: newValue ? "ON" : "OFF")
    }
}
