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

///Delegate protocol to communicate to the SettingsTableViewController some special actions.
protocol SettingsViewControllerDelegate: class {
    /// shows an alert to the user to inform that will leave the group
    func showpEpSyncLeaveGroupAlert()
    /// Shows an alert to the user to inform that all identities will be reseted
    func showResetIdentitiesAlert()
}

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

    weak var settingsDelegate : SettingsViewControllerDelegate?
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
        /// Title of the action row
        var title: String
        /// Indicates if the action to be performed is dangerous.
        var isDangerous: Bool = false
        /// Block that will be executed when action cell is pressed
        var action: ActionBlock
    }

    /// Struct that is used to perform a show detail action. represents a NavicationRow in SettingsTableViewController
    struct NavigationRow: SettingsRowProtocol {
        var title: String
        /// subtitle for a navigation row
        var subtitle: String?
        /// Indicates if the action to be performed is dangerous.
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

    /// Access method to get the sections
    /// - Parameter indexPath: IndexPath of the requested section
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

    /// This method sets up the settings view.
    /// Only this method should be called from the constructor.
    private func setup() {
        generateSections()
    }

    /// This method generates all the sections for the settings view.
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

    /// This method generates all the rows for the section type passed
    /// - Parameter type: The type of the section to generate the rows.
    /// - Returns: An array with the settings rows. Every setting row must conform the SettingsRowProtocol.
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
                me.setPassiveMode(to: value)
            })
            rows.append(generateSwitchRow(type: .protectMessageSubject, isDangerous: false, isOn: false) { [weak self] (value) in
                guard let me = self else {
                    Log.shared.errorAndCrash(message: "Lost myself")
                    return
                }
                me.setProtectMessageSubject(to: value)
            })
        case .pEpSync:
            rows.append(generateSwitchRow(type: .pEpSync, isDangerous: false, isOn: false) { [weak self] (value) in
                guard let me = self else {
                    Log.shared.errorAndCrash(message: "Lost myself")
                    return
                }
                me.setPepSync(to: value)
            })
            rows.append(generateNavigationRow(type: .accountsToSync, isDangerous: false))
        case .contacts:
            rows.append(generateNavigationRow(type: .resetTrust, isDangerous: true))
        case .companyFeatures:
            rows.append(generateNavigationRow(type: .extraKeys, isDangerous: false))
        }
        return rows
    }

    /// This method generates a Navigation Row
    /// - Parameters:
    ///   - type: The type of row to generate
    ///   - isDangerous: If the action that performs this row is dangerous.
    private func generateNavigationRow(type: RowType, isDangerous: Bool) -> NavigationRow {
        guard let rowTitle = rowTitle(type: type) else {
            Log.shared.errorAndCrash(message: "Row title not found")
            return NavigationRow(title: "")
        }
        let subtile = rowSubtitle(type: type)
        return NavigationRow(title:rowTitle, subtitle: subtile, isDangerous: isDangerous)
    }

    /// This method generates a Switch Row
    /// - Parameters:
    ///   - type: The type of row that needs to  generate
    ///   - isDangerous: If the action that performs this row is dangerous.
    ///   - isOn: The default status of the switch
    ///   - action: The action to be performed.
    private func generateSwitchRow(type: RowType, isDangerous: Bool, isOn: Bool,
                                   action: @escaping SwitchBlock) -> SwitchRow {
        guard let rowTitle = rowTitle(type: type) else {
            Log.shared.errorAndCrash(message: "Row title not found")
            return SwitchRow(title: "", isDangerous: true, isOn: true, action: action)
        }
        return SwitchRow(title: rowTitle, isDangerous: isDangerous, isOn: isOn, action: action)
    }

    /// This method generates the action row.
    /// - Parameters:
    ///   - type: The type of row that needs to generate
    ///   - isDangerous: If the action that performs this row is dangerous. (E. g. Reset identities)
    ///   - action: The action to be performed
    private func generateActionRow(type: RowType, isDangerous: Bool,
                                   action: @escaping ActionBlock) -> ActionRow {
        guard let rowTitle = rowTitle(type: type) else {
            Log.shared.errorAndCrash(message: "Row title not found")
            return ActionRow(title: "", action: action)
        }
        return ActionRow(title: rowTitle, isDangerous: isDangerous, action: action)
    }

    /// This method return the corresponding title for each section.
    /// - Parameter type: The section type to choose the proper title.
    /// - Returns: The title for the requested section.
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

    /// Thie method provides the title for the footer of each section.
    /// - Parameter type: The section type to get the proper title
    /// - Returns: The title of the footer. If the section is an account, a pepSync or the company features, it will be nil because there is no footer.
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
    /// - Parameter type: The row type to get the proper title
    /// - Returns: The title of the row. If it's an account row, it will be nil and the name of the account should be used.
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

    /// Thie method provides the subtitle if needed.
    /// - Parameter type: The row type to get the proper title
    /// - Returns: The subtitle of the row.
    private func rowSubtitle(type : RowType) -> String? {
        switch type {
        case .defaultAccount:
            return AppSettings.shared.defaultAccount
        case .account, .accountsToSync, .credits, .extraKeys, .passiveMode, .pEpSync,
             .protectMessageSubject, .resetAccounts, .resetTrust, .setOwnKey, .trustedServer:
            return nil
        }
    }

    ///This method sets the passive mode status according to the parameter value
    /// - Parameter value: The new value of the passive mode status
    private func setPassiveMode(to value: Bool) {
        AppSettings.shared.passiveMode = value
    }

    ///This method sets the Protect Message Subject status according to the parameter value
    /// - Parameter value: The new value of the Protect Message Subject status
    private func setProtectMessageSubject(to value: Bool) {
        AppSettings.shared.unencryptedSubjectEnabled = !value
    }

    ///This method sets the pEp Sync status according to the parameter value
    /// - Parameter value: The new value of the pEp Sync status
    private func setPepSync(to value: Bool) {
        //TODO: implement me!
    }

    ///This method deletes the account passed by parameter.
    /// It also updates the default account if necessary.
    /// - Parameter account: The account to be deleted
    private func delete(account: Account) {
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
