//
//  EditableAccountSettingsViewModel.swift
//  pEp
//
//  Created by Martín Brude on 03/12/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel
import pEpIOSToolbox
import PantomimeFramework

protocol EditableAccountSettingsDelegate: class {
    /// Changes loading view visibility
    /// - Parameter visible: Indicates if it should be visible or not.
    func setLoadingView(visible: Bool)
    /// Shows an alert to inform an error.
    /// - Parameter error: The error to show
    func showAlert(error: Error)
    /// Informs the VC that has to dismiss
    func dismissYourself()
    /// Show Edit Certificate
    func showEditCertificate()
}

class EditableAccountSettingsViewModel {

    // Helper to carry the user input for its validation.
    private typealias Input = (userName: String,
                               emailAddress: String,
                               password: String?,
                               imapServer: String,
                               imapPort: String,
                               imapTranportSecurity: String,
                               imapUsername: String,
                               smtpServer: String,
                               smtpPort: String,
                               smtpTranportSecurity: String,
                               smtpUsername: String)

    /// Indicates if the account is OAuth2
    public private(set) var isOAuth2: Bool = false
    /// Delegate to trigger actions to the VC.
    public weak var delegate: EditableAccountSettingsDelegate?
    /// The sections of Editable Account Settings view.
    /// Delegate to inform the account settings had changed
    public weak var changeDelegate: SettingChangeDelegate?

    public private(set) var sections = [AccountSettingsViewModel.Section]()
    /// Indicates the number ot transport security options.
    public var numberOfTransportSecurityOptions : Int {
        return transportSecurityViewModel.numberOfOptions
    }

    private var passwordChanged: Bool = false
    private var originalPassword: String?

    /// Retrieves the name of an transport security option.
    /// - Parameter index: The index of the option.
    /// - Returns: The name of that option. It could be  Plain, TLS or StartTLS
    public func transportSecurityOption(atIndex index: Int) -> String {
        return transportSecurityViewModel[index]
    }

    /// Retrieves the index of the transtion security option.
    /// - Parameter option: The option to look for its index
    /// - Returns: The index of the option. -1 if not found.
    public func transportSecurityIndex(for option: String) -> Int {
        guard let rawValue = Server.Transport(fromString: option)?.rawValue else {
            return -1
        }
        return Int(rawValue)
    }

    private var account: Account

    /// If there was OAUTH2 for this account, here is a current token.
    /// This trumps both the `originalPassword` and a password given by the user
    /// via the UI.
    /// - Note: For logins that require it, there must be an up-to-date token
    ///         for the verification be able to succeed.
    ///         It is extracted from the existing server credentials on `init`.
    private var accessToken: OAuth2AccessTokenProtocol?

    /// Holding both the data of the current account in verification,
    /// and also the implementation of the verification.
    private var verifiableAccount: VerifiableAccountProtocol?

    private let transportSecurityViewModel = TransportSecurityViewModel()

    private var accountSettingsHelper: AccountSettingsHelper?
    /// Constructor
    /// - Parameters:
    ///   - account: The account to configure the editable account settings view model.
    ///   - delegate: The delegate to communicate to the View Controller.
    public init(account: Account, delegate: EditableAccountSettingsDelegate? = nil) {
         accountSettingsHelper = AccountSettingsHelper(account: account)

        self.account = account
        self.delegate = delegate
        isOAuth2 = account.imapServer?.authMethod == AuthMethod.saslXoauth2.rawValue
        if isOAuth2 {
            if let payload = account.imapServer?.credentials.password ??
                account.smtpServer?.credentials.password,
               let token = OAuth2AccessToken.from(base64Encoded: payload)
                as? OAuth2AccessTokenProtocol {
                accessToken = token
            } else {
                Log.shared.errorAndCrash("Supposed to do OAUTH2, but no existing token")
            }
        } else {
            originalPassword = account.imapServer?.credentials.password
        }
        self.generateSections()
    }

    /// Validates the user input
    /// Upload the changes if everything is OK, else informs the user
    public func handleSaveButtonPressed() {
        delegate?.setLoadingView(visible: true)
        do {
            let validated = try validateInput()
            update(input: validated)
            delegate?.setLoadingView(visible: false)
        } catch {
            delegate?.setLoadingView(visible: false)
            delegate?.showAlert(error: error)
        }
    }

    /// Handles the change of values in the settings.
    /// - Parameters:
    ///   - indexPath: The indexPath of the row that has changed.
    ///   - value: The new value of that row.
    public func handleRowDidChange(at indexPath: IndexPath, value: String) {
        let rows = sections[indexPath.section].rows
        guard let row = rows[indexPath.row]
                as? AccountSettingsViewModel.DisplayRow else {
            Log.shared.errorAndCrash("Can't cast row")
            return
        }
        let rowToReplace = AccountSettingsViewModel.DisplayRow(type: row.type,
                                                               title: row.title,
                                                               text: value,
                                                               cellIdentifier: row.cellIdentifier)
        sections[indexPath.section].rows[indexPath.row] = rowToReplace
        if row.type == .password {
            passwordChanged = true
        }
    }

    public func clientCertificateManagementViewModel() -> ClientCertificateManagementViewModel {
        let verifiableAccount = VerifiableAccount.verifiableAccount(for: .clientCertificate, usePEPFolderProvider: AppSettings.shared)
        let clientCertificateManagementViewModel = ClientCertificateManagementViewModel(verifiableAccount: verifiableAccount, shouldHideCancelButton: false)
        clientCertificateManagementViewModel.accountToUpdate = account
        return clientCertificateManagementViewModel
    }
}

// MARK: -  VerifiableAccountDelegate

extension EditableAccountSettingsViewModel: VerifiableAccountDelegate {

    public func didEndVerification(result: Result<Void, Error>) {
        guard let verifiableAccount = verifiableAccount else {
            Log.shared.errorAndCrash("VerifiableAccount not found")
            return
        }
        switch result {
        case .success:
            do {
                verifiableAccount.save { [weak self] _ in
                    guard let me = self else {
                        //Valid case: the view might be dismissed.
                        return
                    }
                    DispatchQueue.main.async {
                        me.delegate?.setLoadingView(visible: false)
                        me.changeDelegate?.didChange()
                        me.delegate?.dismissYourself()
                    }
                }
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
            }
        }
    }
}

// MARK: -  Private

extension EditableAccountSettingsViewModel {
    // MARK: -  Sections

    /// Generates and retrieves a section
    /// - Parameter type: The type of the section to generate.
    /// - Returns: The generated section.
    private func generateSection(type: AccountSettingsViewModel.SectionType) -> AccountSettingsViewModel.Section {
        guard let accountSettingsHelper = accountSettingsHelper else {
            Log.shared.errorAndCrash("AccountSettingsHelper not found")
            return AccountSettingsViewModel.Section.init(title: "", rows: [], type: .account)
        }
        let rows = generateRows(type: type)
        let title = accountSettingsHelper.sectionTitle(type: type)
        return AccountSettingsViewModel.Section(title: title, rows: rows, type: type)
    }

    private func generateSections() {
        AccountSettingsViewModel.SectionType.allCases.forEach { (type) in
            sections.append(generateSection(type: type))
        }
    }

    // MARK: -  Rows

    /// Generate and return the display row.
    /// - Parameters:
    ///   - type: The type of row.
    ///   - value: The value of the row.
    /// - Returns: The configured row.
    private func getDisplayRow(type: AccountSettingsViewModel.RowType, value: String) -> AccountSettingsViewModel.DisplayRow {
        let cellIdentifier = AccountSettingsHelper.CellsIdentifiers.settingsDisplayCell
        guard let accountSettingsHelper = accountSettingsHelper else {
            Log.shared.errorAndCrash("AccountSettingsHelper not found")
            return AccountSettingsViewModel.DisplayRow(type: .email, title: "", text: "", cellIdentifier: cellIdentifier)
        }
        let title = accountSettingsHelper.rowTitle(for: type)
        let shouldShowCaretOrSelect = type != .tranportSecurity
        return AccountSettingsViewModel.DisplayRow(type: type,
                                                   title: title,
                                                   text: value,
                                                   cellIdentifier: cellIdentifier,
                                                   shouldShowCaret: shouldShowCaretOrSelect,
                                                   shouldSelect: shouldShowCaretOrSelect)
    }

    private func getActionRow(type: AccountSettingsViewModel.RowType, value: String, action: AccountSettingsViewModel.AlertActionBlock) -> AccountSettingsViewModel.ActionRow {
        switch type {
        case .certificate:
            let cellIdentifier = AccountSettingsHelper.CellsIdentifiers.settingsDisplayCell
            guard let accountSettingsHelper = accountSettingsHelper else {
                Log.shared.errorAndCrash("AccountSettingsHelper not found")
                return AccountSettingsViewModel.ActionRow(type: type, title: "", cellIdentifier: cellIdentifier)
            }
            let title = accountSettingsHelper.rowTitle(for: type)
            return AccountSettingsViewModel.ActionRow(type: type,
                                                      title: title,
                                                      text: value,
                                                      isDangerous: false,
                                                      action: { [weak self] in
                                                        guard let me = self else {
                                                            Log.shared.errorAndCrash("Lost myself")
                                                            return
                                                        }
                                                        me.delegate?.showEditCertificate()
                                                      }, cellIdentifier: cellIdentifier)
        default:
            Log.shared.errorAndCrash("Wrong row type for an action row")
            return AccountSettingsViewModel.ActionRow(type: type, title: "", cellIdentifier: "")
        }
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

    /// This method generates all the rows for the section type passed
    /// - Parameter type: The type of the section to generate the rows.
    /// - Returns: An array with the settings rows. Every setting row must conform the SettingsRowProtocol.
    private func generateRows(type: AccountSettingsViewModel.SectionType) -> [AccountSettingsRowProtocol] {
        var rows = [AccountSettingsRowProtocol]()
        switch type {
        case .account:
            guard let name = account.user.userName else {
                Log.shared.errorAndCrash("Name not found")
                return rows
            }
            let nameRow = getDisplayRow(type: .name, value: name)
            rows.append(nameRow)

            // email
            let emailRow = getDisplayRow(type: .email, value: account.user.address)
            rows.append(emailRow)

            // OAuth
            if !isOAuth2 {
                // password
                let fakePassword = "JustAPassword"
                let passwordRow = getDisplayRow(type : .password, value: fakePassword)
                rows.append(passwordRow)
            }
            guard let accountSettingsHelper = accountSettingsHelper else {
                Log.shared.errorAndCrash("AccountSettingsHelper not found")
                return []
            }
            if accountSettingsHelper.hasClientCertificate {
                rows.append(getActionRow(type : .certificate, value: accountSettingsHelper.certificateDescription, action: { [weak self] in
                    guard let me = self else {
                        Log.shared.errorAndCrash("Lost myself")
                        return
                    }
                    me.delegate?.showEditCertificate()
                }))
            }
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

    // MARK: -  Validate input

    private func validateInput() throws -> Input {
        // IMAP
        guard let imapServer = rowValue(sectionType: .imap, rowType: .server) else {
            let msg = NSLocalizedString("IMAP server must not be empty.", comment: "Empty IMAP server message")
            throw AccountSettingsUserInputError.invalidInputServer(localizedMessage: msg)
        }
        guard let imapPort = rowValue(sectionType: .imap, rowType: .port) else {
            let msg = NSLocalizedString("IMAP Port must not be empty.", comment: "Empty IMAP port server message")
            throw AccountSettingsUserInputError.invalidInputPort(localizedMessage: msg)
        }
        guard let imapTransportSecurity = rowValue(sectionType: .imap, rowType: .tranportSecurity) else {
            let msg = NSLocalizedString("Choose IMAP transport security method.", comment: "Empty IMAP transport security method")
            throw AccountSettingsUserInputError.invalidInputTransport(localizedMessage: msg)
        }
        guard let imapUsername = rowValue(sectionType: .imap, rowType: .username) else {
            let msg = NSLocalizedString("Choose IMAP username.", comment: "Empty IMAP username")
            throw AccountSettingsUserInputError.invalidInputTransport(localizedMessage: msg)
        }

        // SMTP
        guard let smtpServer = rowValue(sectionType: .smtp, rowType: .server) else {
            let msg = NSLocalizedString("SMTP server must not be empty.", comment: "Empty SMTP server message")
            throw AccountSettingsUserInputError.invalidInputServer(localizedMessage: msg)
        }
        guard let smtpPort = rowValue(sectionType: .smtp, rowType: .port) else {
            let msg = NSLocalizedString("SMTP Port must not be empty.", comment: "Empty SMTP port server message")
            throw AccountSettingsUserInputError.invalidInputPort(localizedMessage: msg)
        }
        guard let smtpTransportSecurity = rowValue(sectionType: .smtp, rowType: .tranportSecurity) else {
            let msg = NSLocalizedString("Choose SMTP transport security method.", comment: "Empty SMTP transport security method")
            throw AccountSettingsUserInputError.invalidInputTransport(localizedMessage: msg)
        }
        guard let smtpUsername = rowValue(sectionType: .smtp, rowType: .username) else {
            let msg = NSLocalizedString("Choose SMTP username.", comment: "Empty IMAP transport security method")
            throw AccountSettingsUserInputError.invalidInputTransport(localizedMessage: msg)
        }

        // Account
        guard let userName = rowValue(sectionType: .account, rowType: .name) else {
            let msg = NSLocalizedString("Account name must not be empty.", comment: "Empty account name message")
            throw AccountSettingsUserInputError.invalidInputAccountName(localizedMessage: msg)
        }

        guard let emailAddress = rowValue(sectionType: .account, rowType: .email) else {
            Log.shared.errorAndCrash("Email address not found. Is not editable.")
            let msg = NSLocalizedString("Email address must not be empty.", comment: "Email address missing message")
            throw AccountSettingsUserInputError.invalidInputEmailAddress(localizedMessage: msg)
        }

        let newPassword = rowValue(sectionType: .account, rowType: .password)

        return (userName: userName,
                emailAddress: emailAddress,
                password: newPassword,
                imapServer: imapServer,
                imapPort: imapPort,
                imapTranportSecurity: imapTransportSecurity,
                imapUsername: imapUsername,
                smtpServer: smtpServer,
                smtpPort: smtpPort,
                smtpTranportSecurity: smtpTransportSecurity,
                smtpUsername: smtpUsername
        )
    }

    private func rowValue(sectionType: AccountSettingsViewModel.SectionType, rowType: AccountSettingsViewModel.RowType) -> String? {
        guard let sectionIndex = sectionType.index else {
            Log.shared.errorAndCrash("Section not found")
            return nil
        }
        guard let displayRow = sections[sectionIndex].rows.filter({$0.type == rowType}).first as? AccountSettingsViewModel.DisplayRow,
              !displayRow.text.isEmpty else {
            return nil
        }
        return displayRow.text
    }

    private func update(input: Input, password: String? = nil) {
        var theVerifier = verifiableAccount ??
            VerifiableAccount.verifiableAccount(for: .other)
        theVerifier.verifiableAccountDelegate = self
        verifiableAccount = theVerifier

        theVerifier.userName = input.userName
        theVerifier.address = input.emailAddress

        theVerifier.loginNameIMAP = input.imapUsername
        theVerifier.loginNameSMTP = input.smtpUsername

        if isOAuth2 {
            if self.accessToken == nil {
                Log.shared.errorAndCrash("Have to do OAUTH2, but lacking current token")
            }
            theVerifier.authMethod = .saslXoauth2
            theVerifier.accessToken = accessToken
            // OAUTH2 trumps any password
            theVerifier.password = nil
        } else {
            theVerifier.password = originalPassword
            if input.password != nil {
                theVerifier.password = password
            }
            if passwordChanged {
                theVerifier.password = input.password
            } else if originalPassword != nil {
                theVerifier.password = originalPassword
            } else {
                Log.shared.errorAndCrash("Is not OAuth2, hasn't got a new password, nor original password")
                return
            }
        }

        theVerifier.serverIMAP = input.imapServer
        let imapPort = input.imapPort
        if let port = UInt16(imapPort) {
            theVerifier.portIMAP = port
        }
        theVerifier.serverSMTP = input.smtpServer
        let smtpPort = input.smtpPort
        if let port = UInt16(smtpPort) {
            theVerifier.portSMTP = port
        }

        if let transport = Server.Transport(fromString: input.imapTranportSecurity) {
            theVerifier.transportIMAP = ConnectionTransport(transport: transport)
        }

        if let transport = Server.Transport(fromString: input.smtpTranportSecurity) {
            theVerifier.transportSMTP = ConnectionTransport(transport: transport)
        }

        if let clientCertificate = account.imapServer?.credentials.clientCertificate {
            theVerifier.clientCertificate = clientCertificate
        }

        do {
            try theVerifier.verify()
        } catch {
            delegate?.setLoadingView(visible: false)
            delegate?.showAlert(error: LoginViewController.LoginError.noConnectData)
        }
    }

    // MARK: -  TransportSecurityViewModel

    private struct TransportSecurityViewModel {
        public var numberOfOptions: Int {
            return Server.Transport.numberOfOptions
        }

        public subscript(option: Int) -> String {
            get {
                return Server.Transport.allCases[option].asString()
            }
        }
    }
}
