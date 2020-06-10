////
////  AccountSettingsViewModel.swift
////  pEp
////
////  Created by Martin Brude on 13/05/2020.
////  Copyright © 2020 p≡p Security S.A. All rights reserved.
////

import Foundation
import MessageModel
import pEpIOSToolbox

///Delegate protocol to communicate to the Account Settings View Controller
protocol AccountSettingsViewModelDelegate: class {
    //Changes loading view visibility
    func setLoadingView(visible: Bool)
    /// Shows an alert
    func showAlert(error: Error)
    /// Undo the last Pep Sync Change
    func undoPEPSyncToggle()
}

/// Protocol that represents the basic data in a row.
protocol AccountSettingsRowProtocol {
    // The type of the row
    var type : AccountSettingsViewModel.RowType { get }
    /// The title of the row.
    var title: String { get }
    /// Indicates if the row action is dangerous.
    var isDangerous: Bool { get }
    /// Returns the cell identifier based on the index path.
    /// - Parameter type: The row type
    var cellIdentifier: String { get }
}

/// View Model for Account Settings View Controller
final class AccountSettingsViewModel {

    /// If there was OAUTH2 for this account, here is a current token.
    /// This trumps both the `originalPassword` and a password given by the user
    /// via the UI.
    /// - Note: For logins that require it, there must be an up-to-date token
    ///         for the verification be able to succeed.
    ///         It is extracted from the existing server credentials on `init`.
    private var accessToken: OAuth2AccessTokenProtocol?
    private(set) var pEpSync: Bool
    let isOAuth2: Bool
    private(set) var account: Account
    weak var delegate: AccountSettingsViewModelDelegate?
    /// Items to be displayed in a Account Settings View Controller
    private(set) var sections: [Section] = [Section]()

    /// Constructor
    /// - Parameters:
    ///   - account: The account to configure the account settings view model.
    ///   - delegate: The delegate to communicate to the View Controller.
    init(account: Account, delegate: AccountSettingsViewModelDelegate? = nil) {
        self.account = account
        self.delegate = delegate
        pEpSync = (try? account.isKeySyncEnabled()) ?? false
        isOAuth2 = account.imapServer?.authMethod == AuthMethod.saslXoauth2.rawValue
        self.generateSections()
    }
}

// MARK: -  enums & structs

extension AccountSettingsViewModel {
    public typealias SwitchBlock = ((Bool) -> Void)
    public typealias AlertActionBlock = (() -> ())

    /// Identifies semantically the type of row.
    public enum RowType : String {
        case name
        case email
        case password
        case pepSync
        case reset
        case server
        case port
        case tranportSecurity
        case username
        case oauth2Reauth
    }

    /// Identifies the section in the table view.
     public enum SectionType : String {
        case account
        case imap
        case smtp
    }

    /// Struct that represents a section in Account Settings View Controller
     public struct Section: Equatable {
        /// Title of the section
        var title: String
        /// list of rows in the section
        var rows: [AccountSettingsRowProtocol]
        /// type of the section
        var type: SectionType

        static func == (lhs: Section, rhs: Section) -> Bool {
            return false
        }
    }

    /// Struct that is used to show and interact with a switch.
    /// Represents a SwitchRow in Account Settings View Controller
    public struct SwitchRow: AccountSettingsRowProtocol {
        /// Indicates if the action to be performed is dangerous
        var isDangerous: Bool = false
        /// The row type
        var type: AccountSettingsViewModel.RowType
        /// The title of the swith row
        var title: String
        /// Value of the switch
        var isOn: Bool
        /// Action to be executed when switch toggle
        var action: SwitchBlock
        /// The cell identifier
        var cellIdentifier: String
    }

    /// Struct that is used to display information in Account Settings View Controller
     public struct DisplayRow: AccountSettingsRowProtocol {
        /// The row type
        var type: AccountSettingsViewModel.RowType
        /// The title of the row
        var title: String
        /// The text of the row
        var text: String
        /// Indicates if the action to be performed is dangerous
        var isDangerous: Bool = false
        /// The cell identifier
        var cellIdentifier: String
    }

    /// Struct that is used to perform an action.
    /// Represents a ActionRow in in Account Settings View Controller
     public struct ActionRow: AccountSettingsRowProtocol {
        /// The type of the row.
        var type: AccountSettingsViewModel.RowType
        /// Title of the action row
        var title: String
        /// Indicates if the action to be performed is dangerous.
        var isDangerous: Bool = false
        /// Block that will be executed when action cell is pressed
        var action: AlertActionBlock?
        /// The cell identifier
        var cellIdentifier: String
    }
}

//MARK: - Layout

extension AccountSettingsViewModel {

    /// Indicates if the device is in a group.
    /// - Returns: True if the device is in a group.
    public func isPEPSyncSwitchGreyedOut() -> Bool {
        return KeySyncUtil.isInDeviceGroup
    }
}

// MARK: - Client Certificate

extension AccountSettingsViewModel {
    /// Provides information about the certificate
    /// - Returns: Certificate's name and date.
    /// If fails, returns empty string.
    public func certificateInfo() -> String {
        guard let certificate = account.imapServer?.credentials.clientCertificate else {
            return ""
        }
        let name = certificate.label ?? "--"
        let date = certificate.date?.fullString() ?? ""
        let separator = NSLocalizedString("Exp. date:", comment: "spearator string bewtween name and date")
        return "\(name), \(separator) \(date)"
    }

    /// Returns the client certificate View Model
    /// - Returns: Client certificate view model for current account.
    public func clientCertificateViewModel() -> ClientCertificateManagementViewModel {
        return ClientCertificateManagementViewModel(account: account)
    }

    /// Indicates if the account has a client certificate
    /// - Returns: True if the account has a client certificate
    public func hasCertificate() -> Bool {
        return account.imapServer?.credentials.clientCertificate != nil
    }
}

// MARK: - Actions

extension AccountSettingsViewModel {

    /// Handle the Reset Identity action
    /// This resets all the keys of the current account and informs if it fails.
    public func handleResetIdentity() {
        delegate?.setLoadingView(visible: true)
        account.resetKeys() { [weak self] result in
            guard let me = self else {
                Log.shared.lostMySelf()
                return
            }
            switch result {
            case .success():
                me.delegate?.setLoadingView(visible: false)
            case .failure(let error):
                me.delegate?.setLoadingView(visible: false)
                me.delegate?.showAlert(error: error)
                Log.shared.errorAndCrash("Fail to reset identity, with error %@ ",
                                         error.localizedDescription)
            }
        }
    }

    /// [En][Dis]able the pEpSync status
    /// - Parameter enable: The new value.
    /// If the action fails, the undo method from delegate will be
    /// called and an error will be shown.
    public func pEpSync(enable: Bool) {
        do {
            try account.setKeySyncEnabled(enable: enable)
            pEpSync = enable
        } catch {
            delegate?.undoPEPSyncToggle()
            delegate?.showAlert(error: AccountSettingsError.failToModifyAccountPEPSync)
        }
    }
}

// MARK: - OAuthAuthorizer

extension AccountSettingsViewModel {

    /// Update the OAuth token
    /// - Parameter accessToken: the new token.
    public func updateToken(accessToken: OAuth2AccessTokenProtocol) {
        self.accessToken = accessToken
    }
}

// MARK: - Private

extension AccountSettingsViewModel {

    private struct CellsIdentifiers {
        static let oAuthCell = "oAuthTableViewCell"
        static let displayCell = "KeyValueTableViewCell"
        static let switchCell = "SwitchTableViewCell"
        static let dangerousCell = "DangerousTableViewCell"
        static let settingsCell = "settingsCell"
    }

    private enum AccountSettingsError: Error, LocalizedError {
        case accountNotFound, failToModifyAccountPEPSync
        var errorDescription: String? {
            switch self {
            case .accountNotFound, .failToModifyAccountPEPSync:
                return NSLocalizedString("Something went wrong, please try again later", comment: "AccountSettings viewModel: no account error")
            }
        }
    }

    /// This method generates the sections of the account settings view.
    /// Must be called once, at the initialization.
    private func generateSections() {
        sections.append(generateSection(type: .account))
        sections.append(generateSection(type: .imap))
        sections.append(generateSection(type: .smtp))
    }

    /// Generates and retrieves a section
    /// - Parameter type: The type of the section to generate.
    /// - Returns: The generated section.
    private func generateSection(type : SectionType) -> Section {
        let rows = generateRows(type: type)
        let title = sectionTitle(for: type)
        return Section(title: title, rows: rows, type: type)
    }

    /// Provides the title of the section
    /// - Parameter type: The section type
    /// - Returns: the title of the section
    private func sectionTitle(for type : SectionType) -> String {
        switch type {
        case .account:
            return NSLocalizedString("Account", comment: "Account Section")
        case .imap:
            return NSLocalizedString("IMAP", comment: "IMAP Section")
        case .smtp:
            return NSLocalizedString("SMTP", comment: "IMAP Section")
        }
    }

    /// Provides the title of the row
    /// - Parameter type: The type of the row
    /// - Returns: the title of the row.
    private func rowTitle(for type : RowType) -> String {
        switch type {
        case .name:
            return NSLocalizedString("Name", comment: "\(type.rawValue) field")
        case .email:
            return NSLocalizedString("Email", comment: "\(type.rawValue) field")
        case .password:
            return NSLocalizedString("Password", comment: "\(type.rawValue) field")
        case .pepSync:
            return NSLocalizedString("p≡p Sync", comment: "\(type.rawValue) field")
        case .reset:
            return NSLocalizedString("Reset", comment: "\(type.rawValue) field")
        case .server:
            return NSLocalizedString("Server", comment: "\(type.rawValue) field")
        case .port:
            return NSLocalizedString("Port", comment: "\(type.rawValue) field")
        case .tranportSecurity:
            return NSLocalizedString("Transport Security", comment: "\(type.rawValue) field")
        case .username:
            return NSLocalizedString("Username", comment: "\(type.rawValue) field")
        case .oauth2Reauth:
            return NSLocalizedString("OAuth2 Reauthorization", comment: "\(type.rawValue) field")
        }
    }

    /// This method generates all the rows for the section type passed
    /// - Parameter type: The type of the section to generate the rows.
    /// - Returns: An array with the settings rows. Every setting row must conform the SettingsRowProtocol.
    private func generateRows(type: SectionType) -> [AccountSettingsRowProtocol] {
        var rows = [AccountSettingsRowProtocol]()
        switch type {
        case .account:
            // name
            guard let name = account.user.userName else {
                Log.shared.errorAndCrash("Name not found")
                return rows
            }
            let nameTitle = NSLocalizedString("Name", comment: "Name field")
            let nameRow = DisplayRow(type: .name, title: nameTitle, text: name, cellIdentifier: CellsIdentifiers.displayCell)
            rows.append(nameRow)

            // email
            let emailRow = DisplayRow(type: .email,
                                      title: rowTitle(for: .email),
                                      text: account.user.address,
                                      cellIdentifier: CellsIdentifiers.displayCell)
            rows.append(emailRow)

            // OAuth
            if isOAuth2 {
                let oAuthRow = DisplayRow(type: .oauth2Reauth,
                                          title: rowTitle(for: .oauth2Reauth),
                                          text: "",
                                          cellIdentifier: CellsIdentifiers.oAuthCell)
                rows.append(oAuthRow)

            } else {
                // password
                let fakePassword = "JustAPassword"
                let passwordRow = DisplayRow(type: .password,
                                             title: rowTitle(for: .password),
                                             text: fakePassword,
                                             cellIdentifier: CellsIdentifiers.displayCell)
                rows.append(passwordRow)
            }

            // pepSync
            let switchRow = SwitchRow(type: .pepSync,
                                      title: rowTitle(for: .pepSync),
                                      isOn: pEpSync,
                                      action: { [weak self] (enable) in
                                        do {
                                            guard let me = self else {
                                                Log.shared.error("Lost myself")
                                                return
                                            }
                                            try me.account.setKeySyncEnabled(enable: enable)
                                        } catch {
                                            guard let me = self else {
                                                Log.shared.error("Lost myself")
                                                return
                                            }
                                            me.delegate?.undoPEPSyncToggle()
                                            me.delegate?.showAlert(error: AccountSettingsError.failToModifyAccountPEPSync)
                                        }
                }, cellIdentifier: CellsIdentifiers.switchCell)
            rows.append(switchRow)

            // reset
            let resetRow = ActionRow(type: .reset, title: rowTitle(for: .reset), cellIdentifier: CellsIdentifiers.dangerousCell)
            rows.append(resetRow)

        case .imap:
            guard let imapServer = account.imapServer else {
                Log.shared.errorAndCrash("Account without IMAP server")
                return rows
            }

            let serverRow = DisplayRow(type: .server,
                                       title: rowTitle(for: .server),
                                       text: imapServer.address,
                                       cellIdentifier: CellsIdentifiers.displayCell)
            rows.append(serverRow)

            let resetRow = DisplayRow(type: .port,
                                      title: rowTitle(for: .port),
                                      text: String(imapServer.port),
                                      cellIdentifier: CellsIdentifiers.displayCell)
            rows.append(resetRow)

            let transportSecurityRow = DisplayRow(type: .tranportSecurity,
                                                  title: rowTitle(for: .tranportSecurity),
                                                  text: imapServer.transport.asString(),
                                                  cellIdentifier: CellsIdentifiers.displayCell)
            rows.append(transportSecurityRow)

            let usernameRow = DisplayRow(type: .username,
                                         title: rowTitle(for: .username),
                                         text: imapServer.credentials.loginName, cellIdentifier: CellsIdentifiers.displayCell)
            rows.append(usernameRow)

        case .smtp:
            guard let smtpServer = account.smtpServer else {
                Log.shared.errorAndCrash("Account without SMTP server")
                return rows
            }
            let serverRow = DisplayRow(type: .server,
                                       title: rowTitle(for: .server),
                                       text: smtpServer.address,
                                       cellIdentifier: CellsIdentifiers.displayCell)
            rows.append(serverRow)

            let resetRow = DisplayRow(type: .port,
                                      title: rowTitle(for: .port),
                                      text: String(smtpServer.port),
                                      cellIdentifier: CellsIdentifiers.displayCell)
            rows.append(resetRow)

            let transportSecurityRow = DisplayRow(type: .tranportSecurity,
                                                  title: rowTitle(for: .tranportSecurity),
                                                  text: smtpServer.transport.asString(),
                                                  cellIdentifier: CellsIdentifiers.displayCell)
            rows.append(transportSecurityRow)

            let usernameRow = DisplayRow(type: .username,
                                         title: rowTitle(for: .username),
                                         text: smtpServer.credentials.loginName,
                                         cellIdentifier: CellsIdentifiers.displayCell)
            rows.append(usernameRow)
        }
        return rows

    }
}
