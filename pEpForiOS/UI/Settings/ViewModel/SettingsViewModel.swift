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

final class SettingsViewModelV1 {
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

extension SettingsViewModelV1 {

    func isGrouped() -> Bool {
        return KeySyncUtil.isInDeviceGroup
    }

    func PEPSyncUpdate(to value: Bool) {
        let grouped = isGrouped()
        if value {
            KeySyncUtil.enableKeySync()
        } else {
            if grouped {
                do {
                    try KeySyncUtil.leaveDeviceGroup()
                } catch {
                    Log.shared.errorAndCrash(error: error)
                }
            }
            KeySyncUtil.disableKeySync()
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
