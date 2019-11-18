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
        case keySync
        case contacts
        case companyFeatures
    }

    var cells = [SettingCellViewModelProtocol]()
    var title: String?
    var footer: String?
    let type: SectionType
    
    init(type: SectionType, messageModelService: MessageModelServiceProtocol? = nil) {
        self.type = type

        switch type {
        case .accounts:
            guard let messageModelService = messageModelService else {
                Log.shared.errorAndCrash("missing service")
                return
            }
            generateAccountCells(messageModelService: messageModelService)
            title = NSLocalizedString("Accounts", comment: "Tableview section  header")
        case .globalSettings:
            generateGlobalSettingsCells()
            title = NSLocalizedString("Global Settings", comment: "Tableview section header")
            footer = NSLocalizedString("Public key material will only be attached to a message if p≡p detects that the recipient is also using p≡p.",
                                       comment: "passive mode description")
        case .keySync:
            guard let messageModelService = messageModelService else {
                Log.shared.errorAndCrash("missing service")
                return
            }
            generateKeySyncCells(messageModelService)
            title = NSLocalizedString("p≡p sync", comment: "Tableview section header")
        case .contacts:
            generateContactsCells()
            title = NSLocalizedString("Contacts", comment: "TableView section header")
            footer = NSLocalizedString("Performs a reset of the privacy settings saved for a communication partner. Could be needed for example if your communication partner cannot read your messages.",
                                       comment: "TableView Contacts section footer")
        case .companyFeatures:
            generateExtaKeysCells()
            title = NSLocalizedString("Enterprise Features", comment: "Tableview section header")
        }
    }

    var count: Int {
        return cells.count
    }

    subscript(cell: Int) -> SettingCellViewModelProtocol {
        get {
            assert(cellIsValid(cell: cell), "Cell out of range")
            return cells[cell]
        }
    }

    func delete(cell: Int) {
        if let cellToRemove = cells[cell] as? SettingsCellViewModel {
            cellToRemove.delete()
            cells.remove(at: cell)
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

    func cellIsValid(cell: Int) -> Bool {
        return cell >= 0 && cell < cells.count
    }
}

// MARK: - Private

extension SettingsSectionViewModel {

    private func generateAccountCells(messageModelService: MessageModelServiceProtocol) {
        Account.all().forEach { (acc) in
            self.cells.append(SettingsCellViewModel(account: acc,
                                                    messageModelService: messageModelService))
        }
        cells.append(SettingsActionCellViewModel(type: .resetAllIdentities))
    }

    private func generateGlobalSettingsCells() {
        self.cells.append(SettingsCellViewModel(type: .defaultAccount))
        self.cells.append(SettingsCellViewModel(type: .credits))
        self.cells.append(SettingsCellViewModel(type: .trustedServer))
        self.cells.append(SettingsCellViewModel(type: .setOwnKey))
        self.cells.append(PassiveModeViewModel())
        self.cells.append(UnecryptedSubjectViewModel())
    }

    private func generateContactsCells() {
        cells.append(SettingsActionCellViewModel(type: .resetTrust))
    }
}

// MARK: KeySync

extension SettingsSectionViewModel {

    private func generateKeySyncCells(_ messageModelService: MessageModelServiceProtocol) {
        cells.append(EnableKeySyncViewModel(messageModelService))
        if KeySyncDeviceGroupUtil.isInDeviceGroup() {
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
