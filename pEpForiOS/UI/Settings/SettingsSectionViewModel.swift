//
//  SettingsSectionViewModel.swift
//  pEpForiOS
//
//  Created by Xavier Algarra on 08/06/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel

public class SettingsSectionViewModel {

    public enum SectionType {
        case accounts
        case globalSettings
        case pgpCompatibilitySettings
    }

    var cells = [SettingCellViewModelProtocol]()
    var title: String?
    var footer: String?
    let type: SectionType
    
    init(type: SectionType) {
        self.type = type
        switch type {
        case .accounts:
            generateAccountCells()
            title = NSLocalizedString("Accounts", comment: "Tableview section  header")
        case .globalSettings:
            generateGlobalSettingsCells()
            title = NSLocalizedString("Global Settings", comment: "Tableview section header")
            footer = NSLocalizedString("public key is only attached if key is received from partner",
                                       comment: "passive mode description")
        case .pgpCompatibilitySettings:
            generatePgpCompatibilitySettingsCells()
            title = NSLocalizedString("PGP Compatibility", comment: "Tableview section header")
            footer = NSLocalizedString("If enabled, message subjects are also protected.",
                                       comment: "Tableview section footer")
        }
    }

    func generateAccountCells() {
        Account.all().forEach { (acc) in
            self.cells.append(SettingsCellViewModel(account: acc))
        }
    }

    func generateGlobalSettingsCells() {
        self.cells.append(SettingsCellViewModel(type: .defaultAccount))
        self.cells.append(ThreadedSwitchViewModel())
        self.cells.append(SettingsCellViewModel(type: .credits))
        self.cells.append(SettingsCellViewModel(type: .showLog))
        self.cells.append(PassiveModeViewModel())
    }

    func generatePgpCompatibilitySettingsCells() {
        self.cells.append(UnecryptedSubjectViewModel())
    }

    func delete(cell: Int) {
        if let remove = cells[cell] as? SettingsCellViewModel {
            remove.delete()
            cells.remove(at: cell)
        }
    }

    func cellIsValid(cell: Int) -> Bool {
        return cell >= 0 && cell <= cells.count
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
