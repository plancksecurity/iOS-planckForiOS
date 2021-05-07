//
//  AccountSettingsViewModel.swift
//  pEp
//
//  Created by Martin Brude on 13/05/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel
import pEpIOSToolbox
import PantomimeFramework

///Delegate protocol to communicate to the Account Settings View Controller
protocol AccountSettingsViewModelDelegate: class {
    /// Changes loading view visibility
    func setLoadingView(visible: Bool)
    /// Shows an alert
    func showAlert(error: Error)
    ///Informs changes in account Settings
    func didChange()
}

/// Protocol that represents the basic data in a row.
protocol AccountSettingsRowProtocol {
    /// The type of the row
    var type : AccountSettingsViewModel.RowType { get }
    /// The title of the row.
    var title: String { get }
    /// Indicates if the row action is dangerous.
    var isDangerous: Bool { get }
    /// Returns the cell identifier based on the index path.
    var cellIdentifier: String { get }
}

/// View Model for Account Settings View Controller
final class AccountSettingsViewModel {

    public weak var delegate: AccountSettingsViewModelDelegate?

    /// Items to be displayed in a Account Settings View Controller
    /// If there was OAUTH2 for this account, here is a current token.
    /// This trumps both the `originalPassword` and a password given by the user
    /// via the UI.
    /// - Note: For logins that require it, there must be an up-to-date token
    ///         for the verification be able to succeed.
    ///         It is extracted from the existing server credentials on `init`.
    private var accessToken: OAuth2AccessTokenProtocol?
    private(set) var includeInUnifiedFolders: Bool
    private let isOAuth2: Bool
    private(set) var account: Account
    private(set) var sections: [Section] = [Section]()
    private let oauthViewModel = OAuthAuthorizer()
    private lazy var folderSyncService = FetchImapFoldersService()
    private var accountSettingsHelper: AccountSettingsHelper?


    /// If the pEp Sync is enabled for the account.
    public var isPEPSyncEnabled: Bool {
        return account.pEpSyncEnabled
    }

    /// Holding both the data of the current account in verification,
    /// and also the implementation of the verification.
    private var verifiableAccount: VerifiableAccountProtocol?

    /// Constructor
    /// - Parameters:
    ///   - account: The account to configure the account settings view model.
    ///   - delegate: The delegate to communicate to the View Controller.
    init(account: Account, delegate: AccountSettingsViewModelDelegate? = nil) {
        accountSettingsHelper = AccountSettingsHelper(account: account)
        self.account = account
        self.delegate = delegate
        includeInUnifiedFolders = account.isIncludedInUnifiedFolders
        isOAuth2 = account.imapServer?.authMethod == AuthMethod.saslXoauth2.rawValue

        if isOAuth2 {
            if let payload = account.imapServer?.credentials.password ?? account.smtpServer?.credentials.password,
               let token = OAuth2AccessToken.from(base64Encoded: payload) as? OAuth2AccessTokenProtocol {
                accessToken = token
            }
        }

        self.generateSections()
    }

    /// Retrieves the EditableAccountSettingsViewModel
    /// - Parameters:
    ///   - delegate: The EditableAccountSettings delegate
    /// - Returns: The EditableAccountSettingsViewModel
    public func getEditableAccountSettingsViewModel() -> EditableAccountSettingsViewModel {
        let editableAccountSettingsViewModel = EditableAccountSettingsViewModel(account: account)
        editableAccountSettingsViewModel.changeDelegate = self
        return editableAccountSettingsViewModel
    }
}

// MARK: -  enums & structs

extension AccountSettingsViewModel {
    public typealias SwitchBlock = ((Bool) -> Void)
    public typealias AlertActionBlock = (() -> ())

    /// Identifies semantically the type of row.
    public enum RowType : String, CaseIterable {
        case name
        case email
        case password
        case signature
        case includeInUnified
        case pepSync
        case accountActivation
        case reset
        case server
        case port
        case tranportSecurity
        case certificate
        case username
        case oauth2Reauth
    }

    /// Identifies the section in the table view.
    public enum SectionType : String, CaseIterable {
        case account
        case imap
        case smtp
    }

    /// Struct that represents a section in Account Settings View Controller
    public struct Section {
        /// Title of the section
        var title: String
        /// list of rows in the section
        var rows: [AccountSettingsRowProtocol]
        /// type of the section
        var type: SectionType
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
        /// Indicates if the caret should be shown
        var shouldShowCaret: Bool = true
        /// Indicates if the text should be selectable
        var shouldSelect: Bool = true
    }

    /// Struct that is used to perform an action.
    /// Represents a ActionRow in in Account Settings View Controller
    public struct ActionRow: AccountSettingsRowProtocol {
        /// The type of the row.
        var type: AccountSettingsViewModel.RowType
        /// Title of the action row
        var title: String
        /// The text of the row
        var text: String?
        /// Indicates if the action to be performed is dangerous.
        var isDangerous: Bool = false
        /// Block that will be executed when action cell is pressed
        var action: AlertActionBlock?
        /// The cell identifier
        var cellIdentifier: String
    }
}

// MARK: - Actions

extension AccountSettingsViewModel {

    public func handleOauth2Reauth<T: UIViewController>(onViewController vc: T) where T: OAuthAuthorizerDelegate {
        let oauth = OAuth2ProviderFactory().oauth2Provider().createOAuth2Authorizer()
        oauthViewModel.delegate = vc
        oauthViewModel.authorize(
            authorizer: oauth,
            emailAddress: account.user.address,
            accountType: account.accountType,
            viewController: vc)
    }

    /// Handle the Reset Identity action
    /// This resets all the keys of the current account and informs if it fails.
    public func handleResetIdentity() {
        delegate?.setLoadingView(visible: true)
        account.resetKeys() { [weak self] result in
            guard let me = self else {
                // Valid case. We might have been dismissed already.
                return
            }
            switch result {
            case .success():
                DispatchQueue.main.async {
                    me.delegate?.setLoadingView(visible: false)
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    me.delegate?.setLoadingView(visible: false)
                    me.delegate?.showAlert(error: error)
                    Log.shared.errorAndCrash("Fail to reset identity, with error %@ ",
                                             error.localizedDescription)
                }
            }
        }
    }

    /// Handle the change of status of the Unified Folders option.
    /// - Parameter newValue: The value to set. True means enabled, False means disabled. 
    public func handleUnifiedFolderSwitchChanged(to newValue: Bool) {
        includeInUnifiedFolders = newValue
        account.isIncludedInUnifiedFolders = newValue
        account.session.commit()
    }

    /// [En][Dis]able the pEpSync status
    /// - Parameter enable: The new value.
    /// If the action fails, the undo method from delegate will be
    /// called and an error will be shown.
    public func pEpSync(enable: Bool) {
        account.pEpSyncEnabled = enable
    }

    public func handleAccountActivationSwitchChanged(to newValue: Bool) {
        if newValue {
            account.isActive = newValue
            account.session.commit()
        } else {
            verifyAccount()
        }
    }

    /// Indicates if pep synd has to be grayed out.
    /// - Returns: True if it is.
    public func isPEPSyncGrayedOut() -> Bool {
        return KeySyncUtil.isInDeviceGroup
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

    private enum AccountSettingsError: Error, LocalizedError {
        case accountNotFound
        var errorDescription: String? {
            switch self {
            case .accountNotFound:
                return NSLocalizedString("Something went wrong, please try again later", comment: "AccountSettings viewModel: no account error")
            }
        }
    }

    /// This method generates the sections of the account settings view.
    /// Must be called once, at the initialization.
    private func generateSections() {
        SectionType.allCases.forEach { (type) in
            sections.append(generateSection(type: type))
        }
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
            return NSLocalizedString("Name", comment: "Name label in account settings")
        case .email:
            return NSLocalizedString("Email", comment: "Email label in account settings")
        case .password:
            return NSLocalizedString("Password", comment: "Password label in account settings")
        case .pepSync:
            return NSLocalizedString("p≡p Sync", comment: "pEp sync label in account settings")
        case .reset:
            return NSLocalizedString("Reset", comment: "Reset label in account settings")
        case .server:
            return NSLocalizedString("Server", comment: "Server label in account settings")
        case .port:
            return NSLocalizedString("Port", comment: "Port label in account settings")
        case .tranportSecurity:
            return NSLocalizedString("Transport Security",
                                     comment: "Transport security label in account settings")
        case .username:
            return NSLocalizedString("Username", comment: "User name label in account settings")
        case .oauth2Reauth:
            return NSLocalizedString("OAuth2 Reauthorization",
                                     comment: "OAuth2 Reauthorization label in account settings")
        case .includeInUnified:
            return NSLocalizedString("Include in Unified Folders",
                                     comment: "Include in Unified Folders label in account settings")
        case .signature:
            return NSLocalizedString("Signature", comment: "Signature label in account settings")
        case .certificate:
            Log.shared.errorAndCrash("Invalid row type for AccountSettings")
            return ""
        case .accountActivation:
            return NSLocalizedString("Account Activation", comment: "pEp sync label in account settings")
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
            let nameRow = DisplayRow(type: .name, title: nameTitle, text: name, cellIdentifier:  AccountSettingsHelper.CellsIdentifiers.displayCell)
            rows.append(nameRow)

            // email
            let emailRow = getDisplayRow(type: .email, value: account.user.address)
            rows.append(emailRow)

            // OAuth
            if isOAuth2 {
                let oAuthRow = DisplayRow(type: .oauth2Reauth,
                                          title: rowTitle(for: .oauth2Reauth),
                                          text: "",
                                          cellIdentifier: AccountSettingsHelper.CellsIdentifiers.oAuthCell)
                rows.append(oAuthRow)

            } else {
                // password
                let fakePassword = "JustAPassword"
                let passwordRow = getDisplayRow(type : .password, value: fakePassword)
                rows.append(passwordRow)
            }
            
            let signature = account.signature
            let signatureRow = getDisplayRow(type: .signature, value: signature)
            
            rows.append(signatureRow)

            // Include in Unified Folders
            let includeInUnifiedFolderRow = SwitchRow(type: .includeInUnified,
                                                      title: rowTitle(for: .includeInUnified),
                                                      isOn: includeInUnifiedFolders,
                                                      action: { [weak self] (isIncludedInUnifiedFolders) in
                                                        guard let me = self else {
                                                            Log.shared.lostMySelf()
                                                            return
                                                        }
                                                        me.handleUnifiedFolderSwitchChanged(to: isIncludedInUnifiedFolders)
                                                      }, cellIdentifier: AccountSettingsHelper.CellsIdentifiers.switchCell)
            rows.append(includeInUnifiedFolderRow)

            // pepSync
            let pepSyncRow = SwitchRow(type: .pepSync,
                                      title: rowTitle(for: .pepSync),
                                      isOn: true,
                action: { [weak self] (enable) in
                    guard let me = self else {
                        // Valid case. We might have been dismissed.
                        return
                    }
                    me.pEpSync(enable: enable)
                }, cellIdentifier: AccountSettingsHelper.CellsIdentifiers.switchCell)
            rows.append(pepSyncRow)

            // Account Activation
            let accountActivationRow = SwitchRow(type: .accountActivation,
                                                 title: rowTitle(for: .accountActivation),
                                                 isOn: account.isActive,
                                                 action: { [weak self] (isActive) in
                                                    guard let me = self else {
                                                        // Valid case. We might have been dismissed.
                                                        return
                                                    }
                                                    me.handleAccountActivationSwitchChanged(to: isActive)

                                                 }, cellIdentifier: AccountSettingsHelper.CellsIdentifiers.switchCell)
            rows.append(accountActivationRow)

            // reset
            let resetRow = ActionRow(type: .reset, title: rowTitle(for: .reset), cellIdentifier: AccountSettingsHelper.CellsIdentifiers.dangerousCell)
            rows.append(resetRow)

        case .imap:
            guard let imapServer = account.imapServer else {
                Log.shared.errorAndCrash("Account without IMAP server")
                return rows
            }
            setupServerFields(imapServer, &rows)

        case .smtp:
            guard let smtpServer = account.smtpServer else {
                Log.shared.errorAndCrash("Account without SMTP server")
                return rows
            }

            setupServerFields(smtpServer, &rows)
        }
        return rows
    }

    /// Setup the server fields.
    /// - Parameters:
    ///   - server: The server from which to take the values
    ///   - rows: The rows to populate the fields.
    private func setupServerFields(_ server: Server, _ rows: inout [AccountSettingsRowProtocol]) {
        let serverRow = getDisplayRow(type : .server, value: server.address)
        rows.append(serverRow)

        let resetRow = getDisplayRow(type : .port, value: String(server.port))
        rows.append(resetRow)

        let transportSecurityRow = getDisplayRow(type : .tranportSecurity, value: server.transport.asString())
        rows.append(transportSecurityRow)

        let usernameRow = getDisplayRow(type : .username, value: server.credentials.loginName)
        rows.append(usernameRow)
    }

    /// Generate and return the display row.
    /// - Parameters:
    ///   - type: The type of row.
    ///   - value: The value of the row.
    /// - Returns: The configured row.
    private func getDisplayRow(type : RowType, value : String) -> DisplayRow {
        return DisplayRow(type: type,
                          title: rowTitle(for: type),
                          text: value,
                          cellIdentifier: AccountSettingsHelper.CellsIdentifiers.displayCell,
                          shouldShowCaret: type != .tranportSecurity)
    }
}

// MARK: - Key Sync

extension AccountSettingsViewModel {
    
    /// Whether or not pEp Sync is enabled for the current account.
    public func isKeySyncEnabled() -> Bool {
        return account.pEpSyncEnabled
    }
}

// MARK: - Account Activation

extension AccountSettingsViewModel {

    /// Whether or not pEp Sync is enabled for the current account.
    public func isActive() -> Bool {
        return account.isActive
    }
}

// MARK: - Loading

extension AccountSettingsViewModel {

    public func setLoadingView(visible: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let me = self else {
                //Valid case: the view might be dismissed
                return
            }
            me.delegate?.setLoadingView(visible: visible)
        }
    }
}

// MARK: - AccountSettingsDelegate

extension AccountSettingsViewModel: SettingChangeDelegate {

    func didChange() {
        delegate?.didChange()
    }
}

// MARK: - VerifiableAccountDelegate

extension AccountSettingsViewModel: VerifiableAccountDelegate {

    public func didEndVerification(result: Result<Void, Error>) {
        switch result {
        case .success:
            DispatchQueue.main.async { [weak self] in
                guard let me = self else {
                    Log.shared.errorAndCrash("Lost myself")
                    return
                }
                me.account.isActive = false
                me.account.session.commit()
                me.didChange()
                me.delegate?.setLoadingView(visible: false)
            }
        case .failure(let error):
            DispatchQueue.main.async { [weak self] in
                guard let me = self else {
                    //Valid case: the view might be dismissed.
                    return
                }
                me.delegate?.setLoadingView(visible: false)
                if let imapError = error as? ImapSyncOperationError {
                    me.delegate?.showAlert(error: imapError)
                } else if let smtpError = error as? SmtpSendError {
                    me.delegate?.showAlert(error: smtpError)
                } else {
                    Log.shared.errorAndCrash(error: error)
                }
                me.delegate?.didChange()
            }
        }
    }
}

// MARK: -  Verify Account

extension AccountSettingsViewModel {

    private func verifyAccount() {
        delegate?.setLoadingView(visible: true)
        verifiableAccount = VerifiableAccount.verifiableAccount(for: account.accountType)
        verifiableAccount?.verifiableAccountDelegate = self
        guard let imapServer = account.imapServer,
              let smtpServer = account.smtpServer else {
            Log.shared.errorAndCrash("Missing value")
            return
        }
        verifiableAccount?.userName = account.user.userName
        verifiableAccount?.address = account.user.address
        verifiableAccount?.loginNameIMAP = imapServer.credentials.loginName
        verifiableAccount?.loginNameSMTP = smtpServer.credentials.loginName
        if isOAuth2 {
            if self.accessToken == nil {
                Log.shared.errorAndCrash("Have to do OAUTH2, but lacking current token")
            }
            verifiableAccount?.authMethod = .saslXoauth2
            verifiableAccount?.accessToken = accessToken
            // OAUTH2 trumps any password
            verifiableAccount?.password = nil
        } else {
            verifiableAccount?.password = imapServer.credentials.password
        }
        verifiableAccount?.serverIMAP = imapServer.address
        verifiableAccount?.portIMAP = imapServer.port
        verifiableAccount?.serverSMTP = smtpServer.address
        verifiableAccount?.portSMTP = UInt16(smtpServer.port)
        if let imapTransport = Server.Transport(fromString: imapServer.transport.asString()) {
            verifiableAccount?.transportIMAP = ConnectionTransport(transport: imapTransport)
        }
        if let smtpTransport = Server.Transport(fromString: smtpServer.transport.asString()) {
            verifiableAccount?.transportSMTP = ConnectionTransport(transport: smtpTransport)
        }
        if let clientCertificate = account.imapServer?.credentials.clientCertificate {
            verifiableAccount?.clientCertificate = clientCertificate
        }
        do {
            try verifiableAccount?.verify()
        } catch {
            delegate?.setLoadingView(visible: false)
            delegate?.didChange()
            delegate?.showAlert(error: LoginViewController.LoginError.noConnectData)
        }
    }
}
