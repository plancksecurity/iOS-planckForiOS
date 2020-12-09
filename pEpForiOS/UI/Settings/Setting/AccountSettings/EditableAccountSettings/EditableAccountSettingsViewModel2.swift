//
//  EditableAccountSettingsViewModel2.swift
//  pEp
//
//  Created by Martín Brude on 03/12/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel
import pEpIOSToolbox

protocol EditableAccountSettingsDelegate2: class {
    /// Changes loading view visibility
    func setLoadingView(visible: Bool)
    /// Shows an alert
    func showAlert(error: Error)
    /// Informs the VC that has to dismiss
    func dismissYourself()
}

final class EditableAccountSettingsViewModel2 {

    private var account: Account

    public private(set) var isOAuth2: Bool = false
    public weak var delegate: EditableAccountSettingsDelegate2?
    public private(set) var sections = [AccountSettingsViewModel.Section]()

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

    public weak var editableAccountSettingsDelegate: EditableAccountSettingsDelegate?

    public var transportSecurityViewModel = TransportSecurityViewModel()

    /// Constructor
    /// - Parameters:
    ///   - account: The account to configure the editable account settings view model.
    ///   - delegate: The delegate to communicate to the View Controller.
    init(account: Account, delegate: EditableAccountSettingsDelegate2? = nil) {
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
        }

        self.generateSections()
    }

    private func generateSections() {
        AccountSettingsViewModel.SectionType.allCases.forEach { (type) in
            sections.append(generateSection(type: type))
        }
    }

    /// Generates and retrieves a section
    /// - Parameter type: The type of the section to generate.
    /// - Returns: The generated section.
    private func generateSection(type : AccountSettingsViewModel.SectionType) -> AccountSettingsViewModel.Section {
        let rows = generateRows(type: type)
        let title = AccountSettingsHelper.sectionTitle(type: type)
        return AccountSettingsViewModel.Section(title: title, rows: rows, type: type)
    }

    /// Validates the user input
    /// Upload the changes if everything is OK, else informs the user
    public func handleSaveButtonPressed() {
        delegate?.setLoadingView(visible: true)



        delegate?.setLoadingView(visible: false)
    }

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
    }

    private func isInputValid() -> Bool {
        return true
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
}

extension EditableAccountSettingsViewModel2: VerifiableAccountDelegate {
    public func didEndVerification(result: Result<Void, Error>) {
        switch result {
        case .success(()):
            do {
                try verifiableAccount?.save { [weak self] _ in
                    guard let me = self else {
                        //Valid case: the view might be dismissed.
                        return
                    }
                    DispatchQueue.main.async {
                        me.delegate?.setLoadingView(visible: false)
                        me.editableAccountSettingsDelegate?.didChange()
                        me.delegate?.dismissYourself()
                    }
                }
            } catch {
                Log.shared.errorAndCrash(error: error)
                delegate?.setLoadingView(visible: false)
                delegate?.dismissYourself()
            }
        case .failure(let error):
            delegate?.setLoadingView(visible: false)
            if let imapError = error as? ImapSyncOperationError {
                delegate?.showAlert(error: imapError)
            } else if let smtpError = error as? SmtpSendError {
                delegate?.showAlert(error: smtpError)
            } else {
                Log.shared.errorAndCrash(error: error)
            }
        }
    }
}

// MARK: -  enums & structs

extension EditableAccountSettingsViewModel2 {

    public struct TransportSecurityViewModel {
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

extension EditableAccountSettingsViewModel2 {

    public func setLoadingView(visible: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let me = self else {
                //Valid case: the view might be dismissed
                return
            }
            me.delegate?.setLoadingView(visible: visible)
        }
    }

    /// Generate and return the display row.
    /// - Parameters:
    ///   - type: The type of row.
    ///   - value: The value of the row.
    /// - Returns: The configured row.
    private func getDisplayRow(type : AccountSettingsViewModel.RowType, value : String) -> AccountSettingsViewModel.DisplayRow {
        let title = AccountSettingsHelper.rowTitle(for: type)
        let cellIdentifier = AccountSettingsViewModel.CellsIdentifiers.settingsDisplayCell
        return AccountSettingsViewModel.DisplayRow(type: type,
                                                   title: title,
                                                   text: value,
                                                   cellIdentifier: cellIdentifier,
                                                   shouldShowCaret: type != .tranportSecurity)
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
}
