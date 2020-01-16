//
//  SettingsViewModelV2.swift
//  pEp
//
//  Created by Xavier Algarra on 15/01/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel
import pEpIOSToolbox


//protocol SettingsViewControllerDelegate: class {
//    func changePepSync(to: Bool)
//}

/// Protocol that represents the basic data in a row.
protocol SettingsRowProtocol {
    /// Title of the row.
    var title: String { get }
    /// boolean that indicates if the row action is dangerous.
    var isDangerous: Bool { get }
}

/// View Model for SettingsTableViewController
final class SettingsViewModelV2 {

    typealias SwitchBlock = ((Bool) -> Void)
    typealias ActionBlock = (() -> Void)

//    weak var settingsDelegate : SettingsViewControllerDelegate?
    /// Struct that represents a section in settingsTableViewController
    struct Section {
        /// Title of the section
        var title: String
        /// footer of the section
        var footer: String?
        /// list of rows in the section
        var rows: [SettingsRowProtocol]
    }

    /// Struct that is used to perform an action. represents a ActionRow in settingsTableViewController
    struct ActionRow: SettingsRowProtocol {
        var title: String
        var isDangerous: Bool = false
        /// Block that will be executed when action cell is pressed
        var action: ActionBlock
    }

    /// Struct that is used to perform a show detail action. represents a NavicationRow in SettingsTableViewController
    struct NavigationRow: SettingsRowProtocol {
        var title: String
        /// subtitle for a navigation row
        var subtitle: String?
        var isDangerous: Bool = false
    }

    /// Struct that is used to show and interact with a switch. represents a SwitchRow in settingsTableViewController
    struct SwitchRow: SettingsRowProtocol {
        var title: String
        var isDangerous: Bool
        /// Value of the switch
        var isOn: Bool
        /// action to be executed when switch toggle
        var action: SwitchBlock
    }

    /// Items to be displayed in a SettingsTableViewController
    private (set) var items: [Section] = [Section]()

    /// Number of elements in items
    var count: Int {
        get {
            return items.count
        }
    }

    ///Access method to get the sections
    func section(for indexPath: IndexPath) -> Section {
        return items[indexPath.section]
    }

    /// Constructor for SettingsViewModel
    init() {
        setup()
    }

    // MARK: - Private

    private enum SectionType {
        case accounts
        case globalSettings
        case pEpSync
        case contacts
        case companyFeatures
    }

    private enum RowType {
        case account
        case resetAccounts
        case defaultAccount
        case credits
        case trustedServer
        case setOwnKey
        case passiveMode
        case protectMessageSubject
        case pEpSync
        case accountsToSync
        case resetTrust
        case extraKeys
    }

    private func setup() {
        generateSections()
    }

    private func generateSections() {
        items.append(Section(title: sectionTitles(type: .accounts),
                             footer: sectionFooter(type: .accounts),
                             rows: generateRows(type: .accounts)))

        items.append(Section(title: sectionTitles(type: .globalSettings),
                             footer: sectionFooter(type: .globalSettings),
                             rows: generateRows(type: .globalSettings)))

        items.append(Section(title: sectionTitles(type: .pEpSync),
                             footer: sectionFooter(type: .pEpSync),
                             rows: generateRows(type: .pEpSync)))

        items.append(Section(title: sectionTitles(type: .contacts),
                             footer: sectionFooter(type: .contacts),
                             rows: generateRows(type: .contacts)))

        items.append(Section(title: sectionTitles(type: .companyFeatures),
                             footer: sectionFooter(type: .companyFeatures),
                             rows: generateRows(type: .companyFeatures)))
    }

    private func generateRows(type: SectionType) -> [SettingsRowProtocol] {
        var rows = [SettingsRowProtocol]()
        switch type {
        case .accounts:
            Account.all().forEach { (acc) in
                let accountRow = ActionRow(title: acc.user.address,
                                           isDangerous: false, action: { [weak self] in
                                            guard let me = self else {
                                                Log.shared.errorAndCrash(message: "Lost myself")
                                                return
                                            }
                                            me.delete(account: acc)
                })
                rows.append(accountRow)
            }
            rows.append(generateActionRow(type: .resetAccounts, isDangerous: true){})
        case .globalSettings:
            rows.append(generateNavigationRow(type: .defaultAccount, isDangerous: false))
            rows.append(generateNavigationRow(type: .credits, isDangerous: false))
            rows.append(generateNavigationRow(type: .trustedServer, isDangerous: false))
            rows.append(generateNavigationRow(type: .setOwnKey, isDangerous: false))
            rows.append(generateSwitchRow(type: .passiveMode, isDangerous: false, isOn: false) { [weak self] (value) in
                guard let me = self else {
                    Log.shared.errorAndCrash(message: "Lost myself")
                    return
                }
                me.tooglePassiveMode(to: value)
            })
            rows.append(generateSwitchRow(type: .protectMessageSubject, isDangerous: false, isOn: false) { [weak self] (value) in
                guard let me = self else {
                    Log.shared.errorAndCrash(message: "Lost myself")
                    return
                }
                me.toogleProtectMessageSubject(to: value)
            })
        case .pEpSync:
            rows.append(generateSwitchRow(type: .pEpSync, isDangerous: false, isOn: false) { [weak self] (value) in
                guard let me = self else {
                    Log.shared.errorAndCrash(message: "Lost myself")
                    return
                }
                me.tooglePepSync(to: value)
            })
            rows.append(generateNavigationRow(type: .accountsToSync, isDangerous: false))
        case .contacts:
            rows.append(generateNavigationRow(type: .resetTrust, isDangerous: true))
        case .companyFeatures:
            rows.append(generateNavigationRow(type: .extraKeys, isDangerous: false))
        }
        return rows
    }

    private func generateNavigationRow(type: RowType, isDangerous: Bool) -> NavigationRow {
        guard let rowTitle = rowTitle(type: type) else {
            Log.shared.errorAndCrash(message: "Row title not found")
            return NavigationRow(title: "")
        }
        return NavigationRow(title:rowTitle, subtitle: nil, isDangerous: isDangerous)
    }

    private func generateSwitchRow(type: RowType, isDangerous: Bool, isOn: Bool,
                                   action: @escaping SwitchBlock) -> SwitchRow {
        guard let rowTitle = rowTitle(type: type) else {
            Log.shared.errorAndCrash(message: "Row title not found")
            return SwitchRow(title: "", isDangerous: true, isOn: true, action: action)
        }
        return SwitchRow(title: rowTitle, isDangerous: isDangerous, isOn: isOn, action: action)
    }

    private func generateActionRow(type: RowType, isDangerous: Bool,
                                   action: @escaping ActionBlock) -> ActionRow {
        guard let rowTitle = rowTitle(type: type) else {
            Log.shared.errorAndCrash(message: "Row title not found")
            return ActionRow(title: "", action: action)
        }
        return ActionRow(title: rowTitle, isDangerous: isDangerous, action: action)
    }

    private func sectionTitles(type: SectionType) -> String {
        switch type {
        case .accounts:
            return NSLocalizedString("Accounts", comment: "Tableview section  header")
        case .globalSettings:
            return NSLocalizedString("Global Settings", comment: "Tableview section header")
        case .pEpSync:
            return NSLocalizedString("p≡p sync", comment: "Tableview section header")
        case .contacts:
            return NSLocalizedString("Contacts", comment: "TableView section header")
        case .companyFeatures:
            return NSLocalizedString("Enterprise Features", comment: "Tableview section header")
        }
    }

    private func sectionFooter(type: SectionType) -> String? {
        switch type {
        case .accounts, .pEpSync, .companyFeatures:
            return nil
        case .globalSettings:
            return NSLocalizedString("Public key material will only be attached to a message if p≡p detects that the recipient is also using p≡p.",
                                     comment: "passive mode description")
        case .contacts:
            return NSLocalizedString("Performs a reset of the privacy settings saved for a communication partner. Could be needed for example if your communication partner cannot read your messages.",
                                     comment: "TableView Contacts section footer")
        }
    }

    /// Thie method provides the title for each cell, regarding its type.
    private func rowTitle(type : RowType) -> String? {
        switch type {
        case .account:
            return nil
        case .resetAccounts:
            return NSLocalizedString("Reset All Identities", comment: "Settings: Cell (button) title for reset all identities")
        case .credits:
            return NSLocalizedString(
                "Credits",
                comment: "Settings: Cell (button) title to view app credits")
        case .defaultAccount:
            return NSLocalizedString("Default Account", comment:
                "Settings: Cell (button) title to view default account setting")
        case .trustedServer:
            return NSLocalizedString("Store Messages Securely",
                                     comment:
                "Settings: Cell (button) title to view default account setting")
        case .setOwnKey:
            return NSLocalizedString("Set Own Key",
                                     comment:
                "Settings: Cell (button) title for entering fingerprints that are made own keys")
        case .extraKeys:
            return NSLocalizedString("Extra Keys",
                                     comment:
                "Settings: Cell (button) title to view Extra Keys setting")
        case .accountsToSync:
            return NSLocalizedString("Select accounts to sync",
                                     comment: "Settings: Cell (button) title to view accounts to sync")
        case .resetTrust:
            return NSLocalizedString("Reset", comment:
                "Settings: cell (button) title to view the trust contacts option")

        default:
            return ""
        }
    }

    func tooglePassiveMode(to value: Bool) {
        AppSettings.shared.passiveMode = value
    }

    func toogleProtectMessageSubject(to value: Bool) {
        AppSettings.shared.unencryptedSubjectEnabled = !value
    }

    //TODO: implement me!
    func tooglePepSync(to value: Bool) {
//        settingsDelegate?.changePepSync(to: value)
    }

    func delete(account: Account) {

        let oldAddress = account.user.address
        account.delete()
        Session.main.commit()

        if Account.all().count == 1,
            let account = Account.all().first {
            do {
                if try !account.isKeySyncEnabled() {
                    AppSettings.shared.keySyncEnabled = false
                }
            } catch {
                Log.shared.errorAndCrash("Fail to get account pEpSync state")
            }
        }

        if AppSettings.shared.defaultAccount == oldAddress {
            let newDefaultAccount = Account.all().first
            guard let newDefaultAddress = newDefaultAccount?.user.address else {
                return
                //no more accounts, no default account
            }
            AppSettings.shared.defaultAccount = newDefaultAddress
        }
    }
}


//items.append(Section(type: .accounts))

//
//        items.append(Section(title: sectionTitles(type: .accounts),
//                             footer: sectionFooter(type: .accounts),
//                             rows: generateRows(type: .accounts)))


//Section(title: T##String, footer: T##String, rows: T##[SettingsRowProtocol])
//        items.append(Section())//(SettingsSectionViewModel(type: .accounts))
//        items.append(SettingsSectionViewModel(type: .globalSettings))
//        items.append(SettingsSectionViewModel(type: .keySync))
//        items.append(SettingsSectionViewModel(type: .contacts))
//        items.append(SettingsSectionViewModel(type: .companyFeatures))
