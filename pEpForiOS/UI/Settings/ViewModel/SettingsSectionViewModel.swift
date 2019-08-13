//
//  SettingsSectionViewModel.swift
//  pEpForiOS
//
//  Created by Xavier Algarra on 08/06/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel

final class SettingsSectionViewModel {

    public enum SectionType {
        case accounts
        case globalSettings
        case pgpCompatibilitySettings
        case keySync
        case companyFeatures
    }

    var cells = [SettingCellViewModelProtocol]()
    var title: String?
    var footer: String?
    let type: SectionType
    private let keySyncDeviceGroupService: KeySyncDeviceGroupServiceProtocol?
    
    init(type: SectionType, messageModelService: MessageModelServiceProtocol? = nil,
                            keySyncDeviceGroupService: KeySyncDeviceGroupServiceProtocol? = nil) {
        self.type = type
        self.keySyncDeviceGroupService = keySyncDeviceGroupService

        switch type {
        case .accounts:
            generateAccountCells()
            title = NSLocalizedString("Accounts", comment: "Tableview section  header")
        case .globalSettings:
            generateGlobalSettingsCells()
            title = NSLocalizedString("Global Settings", comment: "Tableview section header")
            footer = NSLocalizedString("Public key material will only be attached to a message if p≡p detects that the recipient is also using p≡p.",
                                       comment: "passive mode description")
        case .pgpCompatibilitySettings:
            generatePgpCompatibilitySettingsCells()
            title = NSLocalizedString("PGP Compatibility", comment: "Tableview section header")
            footer = NSLocalizedString("If enabled, message subjects are also protected.",
                                       comment: "Tableview section footer")
        case .keySync:
            guard let messageModelService = messageModelService else {
                Log.shared.errorAndCrash("missing service")
                return
            }
            generateKeySyncCells(messageModelService)
            title = NSLocalizedString("Key sync", comment: "Tableview section header")
        case .companyFeatures:
            generateExtaKeysCells()
            title = NSLocalizedString("Company Features", comment: "Tableview section header")
        }
    }

    //BUFF: move private (and make all generate... and other private)
    func generateAccountCells() {
        Account.all().forEach { (acc) in
            self.cells.append(SettingsCellViewModel(account: acc))
        }
    }

    func removeLeaveDeviceGroupCell() {
        cells.removeAll { cell in
            guard let actionCell = cell as? SettingsActionCellViewModel else {
                return false
            }
            return actionCell.type == .leaveKeySyncGroup
        }
    }

    func generateGlobalSettingsCells() {
        self.cells.append(SettingsCellViewModel(type: .defaultAccount))
        self.cells.append(SettingsCellViewModel(type: .credits))
        self.cells.append(SettingsCellViewModel(type: .trustedServer))
        self.cells.append(SettingsCellViewModel(type: .setOwnKey))
        self.cells.append(PassiveModeViewModel())
    }

    func generatePgpCompatibilitySettingsCells() {
        self.cells.append(UnecryptedSubjectViewModel())
    }

    func delete(cell: Int) {
        if let cellToRemove = cells[cell] as? SettingsCellViewModel {
            cellToRemove.delete()
            cells.remove(at: cell)
        }
    }

    func cellIsValid(cell: Int) -> Bool {
        return cell >= 0 && cell < cells.count
    }

    var count: Int {
        get {
            return cells.count
        }
    }

    subscript(cell: Int) -> SettingCellViewModelProtocol {
        get {
            assert(cellIsValid(cell: cell), "Cell out of range")
            return cells[cell]
        }
    }
}

// MARK: - Private

// MARK: KeySync

extension SettingsSectionViewModel {

    private func isInDeviceGroup() -> Bool {
        guard let keySyncDeviceGroupService = keySyncDeviceGroupService else {
            Log.shared.errorAndCrash("%@", SettingsInternalError.nilKeySyncDeviceGroupService.localizedDescription)
            return false
        }
        return keySyncDeviceGroupService.deviceGroupState == .grouped
    }

    private func generateKeySyncCells(_ messageModelService: MessageModelServiceProtocol) {
        cells.append(EnableKeySyncViewModel(messageModelService))
        if isInDeviceGroup() {
            cells.append(SettingsActionCellViewModel(type: .leaveKeySyncGroup))
        }
    }
}

// MARK: Extra Keys

extension SettingsSectionViewModel {

    private func generateExtaKeysCells() {
        cells.append(SettingsCellViewModel(type: .extraKeys))
    }
}
