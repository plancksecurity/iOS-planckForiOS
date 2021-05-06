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
protocol SettingsViewModelDelegate: class {
    /// Shows the loading
    func showLoadingView()
    /// Hides the loading
    func hideLoadingView()
    /// Shows an alert to indicate if the extra key is editable
    func showExtraKeyEditabilityStateChangeAlert(newValue: String)
    /// Shows an alert to confirm the reset all identities.
    func showResetAllWarning(callback: @escaping SettingsViewModel.ActionBlock)
}

/// Protocol that represents the basic data in a row.
protocol SettingsRowProtocol {
    // Identifier of the row
    var identifier : SettingsViewModel.RowIdentifier { get }
    /// Title of the row.
    var title: String { get }
    /// boolean that indicates if the row action is dangerous.
    var isDangerous: Bool { get }
}

/// View Model for SettingsTableViewController
final class SettingsViewModel {
    private var appSettings: AppSettingsProtocol

    weak var delegate : SettingsViewModelDelegate?
    typealias SwitchBlock = ((Bool) -> Void)
    typealias ActionBlock = (() -> Void)
    typealias AlertActionBlock = (() -> ())

    /// Items to be displayed in a SettingsTableViewController
    private (set) var items: [Section] = [Section]()

    /// Number of elements in items
    public var count: Int {
        get {
            return items.count
        }
    }

    /// Access method to get the sections
    /// - Parameter indexPath: IndexPath of the requested section
    public func section(for indexPath: IndexPath) -> Section {
        return items[indexPath.section]
    }

    ///Access method to get the sections
    public func section(for sectionNumber: Int) -> Section {
        return items[sectionNumber]
    }

    /// Returns the cell identifier based on the index path.
    /// There are 3 cells. SettingsCell, SettingsActionCell, SwitchOptionCell.
    /// - Parameter indexPath: indexPath of the Cell.
    public func cellIdentifier(for indexPath: IndexPath) -> String {
        let row = section(for: indexPath.section).rows[indexPath.row]
        switch row.identifier {
        case .account,
             .defaultAccount,
             .pgpKeyImport,
             .credits,
             .extraKeys,
             .trustedServer,
             .resetTrust, 
             .tutorial:
            return "SettingsCell"
        case .resetAccounts:
            return "SettingsActionCell"
        case .passiveMode,
             .protectMessageSubject,
             .pEpSync,
             .usePEPFolder,
             .unsecureReplyWarningEnabled:
            return "switchOptionCell"
        }
    }

    /// Constructor for SettingsViewModel
    public init(delegate: SettingsViewModelDelegate, appSettings : AppSettingsProtocol = AppSettings.shared) {
        self.appSettings = appSettings
        self.delegate = delegate
        setup()
    }
    
    /// Wrapper method to know if there is no accounts associated.
    /// Returns: True if there are no accounts.
    public func noAccounts() -> Bool {
        return Account.all(onlyActiveAccounts: false).count <= 0
    }
    
    /// Wrapper method to know if the device is in a group.
    /// Returns: True if it is in a group.
    public func isGrouped() -> Bool {
        return KeySyncUtil.isInDeviceGroup
    }

    /// Returns the color of the title for the row passed. Red if the action is dangerous, nil otherwise.
    /// - Parameter rowIdentifier: The identifier of the row type.
    public func titleColor(rowIdentifier: RowIdentifier) -> UIColor? {
        switch rowIdentifier {
        case .resetAccounts, .resetTrust:
            return .pEpRed
        default:
            return nil
        }
    }

    /// Returns the account setted at the the row of the provided indexPath
    /// - Parameter indexPath: The index path to get the account
    public func account(at indexPath : IndexPath) -> Account? {
        let accounts = Account.all(onlyActiveAccounts: false)
        if accounts.count > indexPath.row {
            return accounts[indexPath.row]
        }
        return nil
    }

    /// Handle the tap gesture triggered on the ExtraKeys cell.
    public func handleExtraKeysEditabilityGestureTriggered() {
        let newValue = !AppSettings.shared.extraKeysEditable
        AppSettings.shared.extraKeysEditable = newValue
        delegate?.showExtraKeyEditabilityStateChangeAlert(newValue: newValue ? "ON" : "OFF")
    }

    public func handleResetAllIdentitiesPressed(action: @escaping ActionBlock) {
        delegate?.showResetAllWarning(callback: action)
    }

    public func pgpKeyImportSettingViewModel() -> PGPKeyImportSettingViewModel {
        return PGPKeyImportSettingViewModel()
    }
}

// MARK: - Private

extension SettingsViewModel {

    /// This method sets up the settings view.
    /// Only this method should be called from the constructor.
    private func setup() {
        generateSections()
    }

    /// This method generates all the sections for the settings view.
    private func generateSections() {
        SettingsViewModel.SectionType.allCases.forEach { (type) in
            items.append(sectionForType(sectionType: type))
        }
    }

    private func sectionForType(sectionType: SectionType) -> Section {
        return Section(title: sectionTitle(type: sectionType),
                       footer: sectionFooter(type: sectionType),
                       rows: generateRows(type: sectionType),
                       type: sectionType)
    }

    /// This method generates all the rows for the section type passed
    /// - Parameter type: The type of the section to generate the rows.
    /// - Returns: An array with the settings rows. Every setting row must conform the SettingsRowProtocol.
    private func generateRows(type: SectionType) -> [SettingsRowProtocol] {
        var rows = [SettingsRowProtocol]()
        switch type {
        case .accounts:
            Account.all(onlyActiveAccounts: false).forEach { (acc) in
                var accountRow = ActionRow(identifier: .account, title: acc.user.address,
                                           isDangerous: false)
                accountRow.action = { [weak self] in
                    guard let me = self else {
                        Log.shared.lostMySelf()
                        return
                    }
                    me.appSettings.removeFolderViewCollapsedStateOfAccountWith(address: acc.user.address)
                    me.delete(account: acc)
                    guard let section = me.items.first(where: { (section) -> Bool in
                        return section.type == type
                    }), let index = me.items.firstIndex(of: section) else {
                        Log.shared.error("section lost")
                        return
                    }
                    
                    me.items[index].rows = section.rows.filter { $0.title != accountRow.title }
                }
                rows.append(accountRow)
            }
            rows.append(generateActionRow(type: .resetAccounts, isDangerous: true) { [weak self] in
                guard let me = self else {
                    Log.shared.lostMySelf()
                    return
                }
                
                me.handleResetAllIdentities()
            })
        case .globalSettings:
            rows.append(generateNavigationRow(type: .defaultAccount, isDangerous: false))
            rows.append(generateNavigationRow(type: .credits, isDangerous: false))
            rows.append(generateNavigationRow(type: .trustedServer, isDangerous: false))
            rows.append(generateNavigationRow(type: .pgpKeyImport, isDangerous: false))
            rows.append(generateSwitchRow(type: .unsecureReplyWarningEnabled,
                                          isDangerous: false,
                                          isOn: AppSettings.shared.unsecureReplyWarningEnabled) {  [weak self]
                (value) in
                AppSettings.shared.unsecureReplyWarningEnabled = value
                guard let me = self else {
                    Log.shared.errorAndCrash("Lost myself")
                    return
                }
                me.setSwtichRow(ofType: .globalSettings, withIdentifier: .unsecureReplyWarningEnabled, newValue: value)
            })
            rows.append(generateSwitchRow(type: .protectMessageSubject,
                                          isDangerous: false,
                                          isOn: !AppSettings.shared.unencryptedSubjectEnabled) { [weak self]
                (value) in
                AppSettings.shared.unencryptedSubjectEnabled = !value
                guard let me = self else {
                    Log.shared.errorAndCrash("Lost myself")
                    return
                }
                me.setSwtichRow(ofType: .globalSettings, withIdentifier: .protectMessageSubject, newValue: value)
            })
            rows.append(generateSwitchRow(type: .passiveMode,
                                          isDangerous: false,
                                          isOn: AppSettings.shared.passiveMode) { [weak self] (value) in
                                            AppSettings.shared.passiveMode = value
                guard let me = self else {
                    Log.shared.errorAndCrash("Lost myself")
                    return
                }
                me.setSwtichRow(ofType: .globalSettings, withIdentifier: .passiveMode, newValue: value)

            })
        case .pEpSync:
            rows.append(generateSwitchRow(type: .pEpSync,
                                          isDangerous: false,
                                          isOn: keySyncStatus) { [weak self] (value) in
                guard let me = self else {
                    Log.shared.lostMySelf()
                    return
                }
                me.setPEPSyncEnabled(to: value)
                me.setSwtichRow(ofType: .pEpSync, withIdentifier: .pEpSync, newValue: value)

            })
            rows.append(generateSwitchRow(type: .usePEPFolder,
                                          isDangerous: false,
                                          isOn: AppSettings.shared.usePEPFolderEnabled) { [weak self] (value) in
                AppSettings.shared.usePEPFolderEnabled = value
                guard let me = self else {
                    Log.shared.lostMySelf()
                    return
                }
                me.setSwtichRow(ofType: .pEpSync, withIdentifier: .usePEPFolder, newValue: value)
            })
        case .contacts:
            rows.append(generateNavigationRow(type: .resetTrust, isDangerous: true))
        case .companyFeatures:
            rows.append(generateNavigationRow(type: .extraKeys, isDangerous: false))
        case .tutorial:
            rows.append(generateNavigationRow(type: .tutorial, isDangerous: false))
        }
        return rows
    }

    /// This method generates a Navigation Row
    /// - Parameters:
    ///   - type: The type of row to generate
    ///   - isDangerous: If the action that performs this row is dangerous.
    private func generateNavigationRow(type: RowIdentifier, isDangerous: Bool) -> NavigationRow {
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
    private func generateSwitchRow(type: RowIdentifier, isDangerous: Bool, isOn: Bool,
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
    private func generateActionRow(type: RowIdentifier, isDangerous: Bool,
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
    private func sectionTitle(type: SectionType) -> String {
        switch type {
        case .accounts:
            return NSLocalizedString("Accounts",
                                     comment: "Tableview section  header: Accounts")
        case .globalSettings:
            return NSLocalizedString("Global Settings",
                                     comment: "Tableview section header: Global Settings")
        case .pEpSync:
            return NSLocalizedString("Sync",
                                     comment: "Tableview section header: (p≡p) Sync")
        case .contacts:
            return NSLocalizedString("Contacts",
                                     comment: "TableView section header: Contacts")
        case .companyFeatures:
            return NSLocalizedString("Enterprise Features",
                                     comment: "Tableview section header: Enterprise Features")
        case .tutorial:
            return NSLocalizedString("Tutorial",
                                     comment: "Tableview section header: Tutorial")
        }
    }

    /// Thie method provides the title for the footer of each section.
    /// - Parameter type: The section type to get the proper title
    /// - Returns: The title of the footer. If the section is an account, a pepSync or the company features, it will be nil because there is no footer.
    private func sectionFooter(type: SectionType) -> String? {
        switch type {
        case .pEpSync, .companyFeatures, .tutorial:
            return nil
        case .accounts:
            return NSLocalizedString("Performs a reset of the privacy settings of your account(s)",
                                     comment: "Settings accounts section, footer below Reset All cell")
        case .globalSettings:
            return NSLocalizedString("Public key material will only be attached to a message if p≡p detects that the recipient is also using p≡p.",
                                     comment: "passive mode description")
        case .contacts:
            return NSLocalizedString("Performs a reset of the privacy settings saved for a communication partner. Could be needed for example if your communication partner cannot read your messages.",
                                     comment: "TableView Contacts section footer")
        }
    }

    /// This method provides the title for each cell, regarding its type.
    /// - Parameter type: The row type to get the proper title
    /// - Returns: The title of the row. If it's an account row, it will be nil and the name of the account should be used.
    private func rowTitle(type : RowIdentifier) -> String? {
        switch type {
        case .account:
            return nil
        case .resetAccounts:
            return NSLocalizedString("Reset All",
                                     comment: "Settings: Cell (button) title for reset all identities")
        case .credits:
            return NSLocalizedString("Credits",
                                     comment: "Settings: Cell (button) title to view app credits")
        case .defaultAccount:
            return NSLocalizedString("Default Account",
                                     comment: "Settings: Cell (button) title to view default account setting")
        case .trustedServer:
            return NSLocalizedString("Store Messages Securely",
                                     comment: "Settings: Cell (button) title to view default account setting")
        case .pgpKeyImport:
            return NSLocalizedString("PGP Key Import",
                                     comment: "Settings: Cell (button) title for importing and using private PGP keys")
        case .extraKeys:
            return NSLocalizedString("Extra Keys",
                                     comment: "Settings: Cell (button) title to view Extra Keys setting")
        case .resetTrust:
            return NSLocalizedString("Reset",
                                     comment: "Settings: cell (button) title to view the trust contacts option")
        case .passiveMode:
            return NSLocalizedString("Passive mode",
                                     comment: "Passive mode title")
        case .protectMessageSubject:
            return NSLocalizedString("Protect Message Subject",
                                     comment: "title for subject protection")
        case .pEpSync:
            return NSLocalizedString("p≡p Sync",
                                     comment: "Settings: enable/disable p≡p Sync feature")
        case .usePEPFolder:
            return NSLocalizedString("Use p≡p Folder For Sync Messages",
                                     comment: "Settings: title for enable/disable usePEPFolder feature")
        case .unsecureReplyWarningEnabled:
            return NSLocalizedString("Unsecure reply warning",
                                     comment: "setting row title: Unsecure reply warning")
        case .tutorial:
            return NSLocalizedString("Tutorial", comment: "setting row title: Tutorial")
        }
    }

    /// This method provides the subtitle if needed.
    /// - Parameter type: The row type to get the proper title
    /// - Returns: The subtitle of the row.
    private func rowSubtitle(type : RowIdentifier) -> String? {
        switch type {
        case .defaultAccount:
            return AppSettings.shared.defaultAccount
        case .account,
             .credits,
             .extraKeys,
             .passiveMode,
             .pEpSync,
             .usePEPFolder,
             .protectMessageSubject,
             .resetAccounts,
             .resetTrust,
             .pgpKeyImport,
             .trustedServer,
             .unsecureReplyWarningEnabled, .tutorial:
            return nil
        }
    }

    /// Set the new value of the switch row.
    ///
    /// - Parameters:
    ///   - sectionType: The section type.
    ///   - identifier: The row identifier.
    ///   - newValue: The value to set.
    private func setSwtichRow(ofType sectionType: SectionType, withIdentifier identifier: SettingsViewModel.RowIdentifier, newValue: Bool) {
        guard let sectionIndex = sectionType.index else {
            Log.shared.errorAndCrash("section index not found")
            return
        }
        guard let rowIndex = items[sectionIndex].rows.firstIndex(where: { $0.identifier == identifier }) else {
            Log.shared.errorAndCrash("row index not found")
            return
        }
        guard var row = items[sectionIndex].rows[rowIndex] as? SwitchRow else {
            Log.shared.errorAndCrash("can't cast row")
            return
        }
        row.isOn = newValue
        items[sectionIndex].rows[rowIndex] = row
    }

    /// This method sets the pEp Sync status according to the parameter value
    /// - Parameter value: The new value of the pEp Sync status
    private func setPEPSyncEnabled(to value: Bool) {
        let grouped = KeySyncUtil.isInDeviceGroup
        if value {
            KeySyncUtil.enableKeySync()
        } else {
            if grouped {
                KeySyncUtil.leaveDeviceGroup() {
                    // Nothing to do.
                }
            } else {
                KeySyncUtil.disableKeySync()
            }
        }
    }

    private var keySyncStatus: Bool {
        get {
            AppSettings.shared.isKeySyncEnabled
        }
    }

    ///This method deletes the account passed by parameter.
    /// It also updates the default account if necessary.
    /// - Parameter account: The account to be deleted
    private func delete(account: Account) {
        account.pEpSyncEnabled = false
        let oldAddress = account.user.address
        account.delete()
        Session.main.commit()

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

    /// Handle method to respond to the reset all identities button.
    private func handleResetAllIdentities() {
        delegate?.showLoadingView()
        Account.resetAllOwnKeys() { [weak self] result in
            switch result {
            case .success:
                Log.shared.info("Success", [])
                self?.delegate?.hideLoadingView()
            case .failure(let error):
                self?.delegate?.hideLoadingView()
                Log.shared.errorAndCrash("Fail to reset all identities, with error %@ ",
                                         error.localizedDescription)
            }
        }
    }
}

// MARK: - Public enums & structs

extension SettingsViewModel {
    /// Identifies the section in the table view.
    public enum SectionType : String, CaseIterable {
        case accounts
        case globalSettings
        case pEpSync
        case companyFeatures
        case tutorial
        case contacts
    }

    /// Identifies semantically the type of row.
    public enum RowIdentifier: String {
        case account
        case resetAccounts
        case defaultAccount
        case credits
        case trustedServer
        case pgpKeyImport
        case passiveMode
        case protectMessageSubject
        case unsecureReplyWarningEnabled
        case pEpSync
        case usePEPFolder
        case resetTrust
        case extraKeys
        case tutorial
    }

    /// Struct that represents a section in SettingsTableViewController
    public struct Section: Equatable {
        /// Title of the section
        var title: String
        /// footer of the section
        var footer: String?
        /// list of rows in the section
        var rows: [SettingsRowProtocol]
        /// type of the section
        var type: SectionType

        static func == (lhs: SettingsViewModel.Section, rhs: SettingsViewModel.Section) -> Bool {
            return (lhs.title == rhs.title && lhs.footer == rhs.footer)
        }
    }
}

// MARK: - Public structs to use SettingsViewModel

extension SettingsViewModel {

    /// Struct that is used to perform an action. represents a ActionRow in settingsTableViewController
    public struct ActionRow: SettingsRowProtocol {
        /// The type of the row.
        var identifier: SettingsViewModel.RowIdentifier
        /// Title of the action row
        var title: String
        /// Indicates if the action to be performed is dangerous.
        var isDangerous: Bool = false
        /// Block that will be executed when action cell is pressed
        var action: ActionBlock?
    }

    /// Struct that is used to perform a show detail action. represents a NavicationRow in SettingsTableViewController
    public struct NavigationRow: SettingsRowProtocol {
        /// The type of the row.
        var identifier: SettingsViewModel.RowIdentifier
        /// Title of the action row
        var title: String
        /// subtitle for a navigation row
        var subtitle: String?
        /// Indicates if the action to be performed is dangerous.
        var isDangerous: Bool = false
    }

    /// Struct that is used to show and interact with a switch. represents a SwitchRow in settingsTableViewController
    public struct SwitchRow: SettingsRowProtocol {
        //The row type
        var identifier: SettingsViewModel.RowIdentifier
        //The title of the swith row
        var title: String
        //Indicates if the action to be performed is dangerous
        var isDangerous: Bool
        /// Value of the switch
        var isOn: Bool
        /// action to be executed when switch toggle
        var action: SwitchBlock
    }
}
