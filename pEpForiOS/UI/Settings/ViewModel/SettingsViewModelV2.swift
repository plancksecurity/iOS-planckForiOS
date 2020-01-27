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
    /// Shows the loading
    func showLoadingView()
    /// Hides the loading
    func hideLoadingView()
    /// Shows an alert to indicate if the extra key is editable
    func showExtraKeyEditabilityStateChangeAlert(newValue: String)
}

/// Protocol that represents the basic data in a row.
protocol SettingsRowProtocol {
    // Identifier of the row
    var identifier : SettingsViewModel.Row { get }
    /// Title of the row.
    var title: String { get }
    /// boolean that indicates if the row action is dangerous.
    var isDangerous: Bool { get }
}

/// View Model for SettingsTableViewController
final class SettingsViewModel {

    weak var delegate : SettingsViewControllerDelegate?
    typealias SwitchBlock = ((Bool) -> Void)
    //typealias ActionBlock = ((IndexPath) -> Void)
    typealias ActionBlock = (() -> Void)
    typealias AlertActionBlock = (() -> ())

    /// Struct that represents a section in settingsTableViewController
    struct Section: Equatable {
        /// Title of the section
        var title: String
        /// footer of the section
        var footer: String?
        /// list of rows in the section
        var rows: [SettingsRowProtocol]
    
        static func == (lhs: SettingsViewModel.Section, rhs: SettingsViewModel.Section) -> Bool {
// !!!:            missing row equal
            return (lhs.title == rhs.title && lhs.footer == rhs.footer)
        }
    }

    /// Struct that is used to perform an action. represents a ActionRow in settingsTableViewController
    struct ActionRow: SettingsRowProtocol, Equatable {
        /// The type of the row.
        var identifier: SettingsViewModel.Row
        /// Title of the action row
        var title: String
        /// Indicates if the action to be performed is dangerous.
        var isDangerous: Bool = false
        /// Block that will be executed when action cell is pressed
        var action: ActionBlock?
        
        static func == (lhs: SettingsViewModel.ActionRow, rhs: SettingsViewModel.ActionRow) -> Bool {
// !!!:           missing row action
            return lhs.title == rhs.title && lhs.identifier == rhs.identifier && lhs.isDangerous == rhs.isDangerous
        }
    }

    /// Struct that is used to perform a show detail action. represents a NavicationRow in SettingsTableViewController
    struct NavigationRow: SettingsRowProtocol {
        /// The type of the row.
        var identifier: SettingsViewModel.Row
        /// Title of the action row
        var title: String
        /// subtitle for a navigation row
        var subtitle: String?
        /// Indicates if the action to be performed is dangerous.
        var isDangerous: Bool = false
    }

    /// Struct that is used to show and interact with a switch. represents a SwitchRow in settingsTableViewController
    struct SwitchRow: SettingsRowProtocol {
        //The row type
        var identifier: SettingsViewModel.Row
        //The title of the swith row
        var title: String
        //Indicates if the action to be performed is dangerous
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

    ///Access method to get the sections
    func section(for sectionNumber: Int) -> Section {
        return items[sectionNumber]
    }

    /// Returns the cell identifier based on the index path.
    /// There are 3 cells. SettingsCell, SettingsActionCell, SwitchOptionCell.
    /// - Parameter indexPath: indexPath of the Cell.
    func cellIdentifier(for indexPath: IndexPath) -> String {
        let row = section(for: indexPath.section).rows[indexPath.row]
        switch row.identifier {
        case .account, .defaultAccount, .setOwnKey, .credits, .extraKeys, .trustedServer:
            return "SettingsCell"
        case .resetAccounts, .accountsToSync, .resetTrust, .pEpSync:
            return "SettingsActionCell"
        case .passiveMode, .protectMessageSubject:
            return "switchOptionCell"
        }
    }

    /// Constructor for SettingsViewModel
    init() {
        setup()
    }

    // MARK: - Private
    
    /// Identifies the section in the table view.
    enum SectionType : CaseIterable {
        case accounts
        case globalSettings
        case pEpSync
        case contacts
        case companyFeatures
    }

    //Identifies visually the type of row.
    enum RowType {
        case action
        case swipe
        case navigation
        case all
    }
    
    //Identifies semantically the type of row.
    enum Row {
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
    
    /// Identifier of the segues.
    enum SegueIdentifier: String {
        case segueAddNewAccount
        case segueEditAccount
        case segueShowSettingDefaultAccount
        case sequeShowCredits
        case segueShowSettingTrustedServers
        case segueExtraKeys
        case segueSetOwnKey
        case seguePerAccountSync
        case noAccounts
        case ResetTrustSplitView
        case ResetTrust
        case noSegue
        case passiveMode
        case protectMessageSubject
        case pEpSync
        case resetAccounts
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
                var accountRow = ActionRow(identifier: .account, title: acc.user.address,
                                           isDangerous: false)
                accountRow.action = { [weak self] in
                                            guard let me = self else {
                                                Log.shared.errorAndCrash(message: "Lost myself")
                                                return
                                            }
                                            //Delete the account
                                            me.delete(account: acc)
//                    !!!: remove 0 and use type of SectionType to find and remove the row
                    me.items[0].rows = me.items[0].rows.filter {$0.title != accountRow.title }
                                    }
                rows.append(accountRow)
            }
            rows.append(generateActionRow(type: .resetAccounts, isDangerous: true) { [weak self] in
                guard let me = self else {
                    Log.shared.errorAndCrash(message: "Lost myself")
                    return
                }

                me.handleResetAllIdentities()
            })
        case .globalSettings:
            rows.append(generateNavigationRow(type: .defaultAccount, isDangerous: false))
            rows.append(generateNavigationRow(type: .credits, isDangerous: false))
            rows.append(generateNavigationRow(type: .trustedServer, isDangerous: false))
            rows.append(generateNavigationRow(type: .setOwnKey, isDangerous: false))
            rows.append(generateSwitchRow(type: .passiveMode, isDangerous: false, isOn: passiveModeStatus) { [weak self] (value) in
                guard let me = self else {
                    Log.shared.errorAndCrash(message: "Lost myself")
                    return
                }
                me.setPassiveMode(to: value)
            })
            rows.append(generateSwitchRow(type: .protectMessageSubject, isDangerous: false, isOn: protectedMessageStatus) { [weak self] (value) in
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
            //TODO: WTF? 
            // rows.append(generateNavigationRow(type: .accountsToSync, isDangerous: false))
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
    private func generateNavigationRow(type: Row, isDangerous: Bool) -> NavigationRow {
        guard let rowTitle = rowTitle(type: type) else {
            Log.shared.errorAndCrash(message: "Row title not found")
            return NavigationRow(identifier: type, title: "")
        }
        let subtile = rowSubtitle(type: type)
        return NavigationRow(identifier: type, title:rowTitle, subtitle: subtile, isDangerous: isDangerous)
    }

    /// This method generates a Switch Row
    /// - Parameters:
    ///   - type: The type of row that needs to  generate
    ///   - isDangerous: If the action that performs this row is dangerous.
    ///   - isOn: The default status of the switch
    ///   - action: The action to be performed.
    private func generateSwitchRow(type: Row, isDangerous: Bool, isOn: Bool,
                                   action: @escaping SwitchBlock) -> SwitchRow {
        guard let rowTitle = rowTitle(type: type) else {
            Log.shared.errorAndCrash(message: "Row title not found")
            return SwitchRow(identifier: type, title: "", isDangerous: true, isOn: true, action: action)
        }
        return SwitchRow(identifier: type, title: rowTitle, isDangerous: isDangerous, isOn: isOn, action: action)
    }

    /// This method generates the action row.
    /// - Parameters:
    ///   - type: The type of row that needs to generate
    ///   - isDangerous: If the action that performs this row is dangerous. (E. g. Reset identities)
    ///   - action: The action to be performed
    private func generateActionRow(type: Row, isDangerous: Bool,
                                   action: @escaping ActionBlock) -> ActionRow {
        guard let rowTitle = rowTitle(type: type) else {
            Log.shared.errorAndCrash(message: "Row title not found")
            return ActionRow(identifier: type, title: "", action: action)
        }
        return ActionRow(identifier: type, title: rowTitle, isDangerous: isDangerous, action: action)
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
    private func rowTitle(type : Row) -> String? {
        switch type {
        case .account:
            return nil
        case .resetAccounts:
            return NSLocalizedString("Reset All Identities", comment: "Settings: Cell (button) title for reset all identities")
        case .credits:
            return NSLocalizedString("Credits", comment: "Settings: Cell (button) title to view app credits")
        case .defaultAccount:
            return NSLocalizedString("Default Account", comment: "Settings: Cell (button) title to view default account setting")
        case .trustedServer:
            return NSLocalizedString("Store Messages Securely", comment: "Settings: Cell (button) title to view default account setting")
        case .setOwnKey:
            return NSLocalizedString("Set Own Key", comment: "Settings: Cell (button) title for entering fingerprints that are made own keys")
        case .extraKeys:
            return NSLocalizedString("Extra Keys", comment: "Settings: Cell (button) title to view Extra Keys setting")
        case .accountsToSync:
            return NSLocalizedString("Select accounts to sync", comment: "Settings: Cell (button) title to view accounts to sync")
        case .resetTrust:
            return NSLocalizedString("Reset", comment: "Settings: cell (button) title to view the trust contacts option")
        case .passiveMode:
            return NSLocalizedString("Enable passive mode", comment: "Passive mode title")
        case .protectMessageSubject:
            return NSLocalizedString("Protect Message Subject", comment: "title for subject protection")
        case .pEpSync:
            return NSLocalizedString("Enable p≡p Sync", comment: "settings, enable thread view or not")
        }
    }

    /// Thie method provides the subtitle if needed.
    /// - Parameter type: The row type to get the proper title
    /// - Returns: The subtitle of the row.
    private func rowSubtitle(type : Row) -> String? {
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
    
    private var passiveModeStatus: Bool {
        get {
            AppSettings.shared.passiveMode
        }
    }

    ///This method sets the Protect Message Subject status according to the parameter value
    /// - Parameter value: The new value of the Protect Message Subject status
    private func setProtectMessageSubject(to value: Bool) {
        AppSettings.shared.unencryptedSubjectEnabled = !value
    }
    
    private var protectedMessageStatus: Bool {
        get {
            AppSettings.shared.unencryptedSubjectEnabled
        }
    }

    /////TODO: implement me!
    /// This method sets the pEp Sync status according to the parameter value
    /// - Parameter value: The new value of the pEp Sync status
    private func setPepSync(to value: Bool) {
        
    }

    ///This method deletes the account passed by parameter.
    /// It also updates the default account if necessary.
    /// - Parameter account: The account to be deleted
    private func delete(account: Account) {
        let oldAddress = account.user.address
        account.delete()
        Session.main.commit()
        if Account.all().count == 1, let account = Account.all().first {
            do {
                if try !account.isKeySyncEnabled() {
                    AppSettings.shared.keySyncEnabled = false
                }
            } catch {
                Log.shared.errorAndCrash("Fail to get account pEpSync state")
            }
        }

        if AppSettings.shared.defaultAccount == nil ||
            AppSettings.shared.defaultAccount == oldAddress {
            let newDefaultAccount = Account.all().first
            guard let newDefaultAddress = newDefaultAccount?.user.address else {
                return
                //no more accounts, no default account
            }
            AppSettings.shared.defaultAccount = newDefaultAddress
        }
    }
    
    //!!!: - COPY - PASTED FROM SETTINGS VIEW MODEL 1!
    ///REVIEW THIS , if it's okey, write documentation.
    func PEPSyncUpdate(to value: Bool) {
        let grouped = KeySyncUtil.isInDeviceGroup
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
    
    /// Handle method to respond to the reset all identities button.
    func handleResetAllIdentities() {
        delegate?.showLoadingView()
        Account.resetAllOwnKeys() { [weak self] result in
            switch result {
            case .success():
                Log.shared.info("Success", [])
                self?.delegate?.hideLoadingView()
            case .failure(let error):
                self?.delegate?.hideLoadingView()
                Log.shared.errorAndCrash("Fail to reset all identities, with error %@ ",
                                         error.localizedDescription)
            }
        }
    }
    
    /// Wrapper method to know if there is no accounts associated.
    /// Returns: True if there are no accounts.
    func noAccounts() -> Bool {
        return Account.all().count <= 0
    }
    
    /// Wrapper method to know if the device is in a group.
    /// Returns: True if it is in a group.
    func isGrouped() -> Bool {
        return KeySyncUtil.isInDeviceGroup
    }

    func pEpSyncSection() -> Int? {
        return SectionType.pEpSync.index
    }
    
    /// Returns the color of the title for the row passed. Red if the action is dangerous, nil otherwise.
    /// - Parameter rowIdentifier: The identifier of the row type.
    func titleColor(rowIdentifier: Row) -> UIColor? {
        switch rowIdentifier {
        case .resetAccounts, .resetTrust:
            return .pEpRed
        default:
            return nil
        }
    }
    
    /// Returns the account setted at the the row of the provided indexPath
    /// - Parameter indexPath: The index path to get the account
    func account(at indexPath : IndexPath) -> Account? {
        let accounts = Account.all()
        if accounts.count > indexPath.row {
            return accounts[indexPath.row]
        }
        return nil
    }
    
    /// Deletes the row at the passed index Path
    /// - Parameter indexPath: The index Path to
    func deleteRowAt(_ indexPath: IndexPath) {
        items[indexPath.section].rows.remove(at: indexPath.row)
    }
}

extension SettingsViewModel {
    
    /// Handle the tap gesture triggered on the ExtraKeys cell.
    func handleExtraKeysEditabilityGestureTriggered() {
        let newValue = !AppSettings.shared.extraKeysEditable
        AppSettings.shared.extraKeysEditable = newValue
        
        delegate?.showExtraKeyEditabilityStateChangeAlert(newValue: newValue ? "ON" : "OFF")
    }
}
