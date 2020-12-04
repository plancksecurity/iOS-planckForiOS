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
    /// Informs that the account settings had chaged
    func accountSettingsDidChange()
    /// Dismiss the currently presented VC
    func popViewController()
}

final class EditableAccountSettingsViewModel2 {

    private var account: Account

    //MB:- Repeated
    public var isOAuth2: Bool = false

    public weak var delegate: EditableAccountSettingsDelegate2?
    public let securityViewModel = SecurityViewModel2()

    public private(set) var sections = [AccountSettingsViewModel.Section]()


    /// If there was OAUTH2 for this account, here is a current token.
    /// This trumps both the `originalPassword` and a password given by the user
    /// via the UI.
    /// - Note: For logins that require it, there must be an up-to-date token
    ///         for the verification be able to succeed.
    ///         It is extracted from the existing server credentials on `init`.
    private var accessToken: OAuth2AccessTokenProtocol?

    /// Constructor
    /// - Parameters:
    ///   - account: The account to configure the editable account settings view model.
    ///   - delegate: The delegate to communicate to the View Controller.
    init(account: Account, editableAccountSettingsDelegate: EditableAccountSettingsDelegate2? = nil) {
        self.account = account
        self.delegate = editableAccountSettingsDelegate
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
        let title = sectionTitle(type: type)
        return AccountSettingsViewModel.Section(title: title, rows: rows, type: type)
    }

    /// Validates the user input
    /// Upload the changes if everything is OK, else informs the user
    public func handleSaveButtonPressed() {

    }

    public func handleRowDidChange(row: Int, value: String) {

    }


    /// This method generates all the rows for the section type passed
    /// - Parameter type: The type of the section to generate the rows.
    /// - Returns: An array with the settings rows. Every setting row must conform the SettingsRowProtocol.
    private func generateRows(type: AccountSettingsViewModel.SectionType) -> [AccountSettingsRowProtocol] {
        var rows = [AccountSettingsRowProtocol]()
        switch type {
        case .account:
            print("")

            // name
            guard let name = account.user.userName else {
                Log.shared.errorAndCrash("Name not found")
                return rows
            }
            let nameTitle = NSLocalizedString("Name", comment: "Name field")
            let nameRow = AccountSettingsViewModel.DisplayRow(type: .name, title: nameTitle, text: name, cellIdentifier: CellsIdentifiers.displayCell)
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
//        switch result {
//        case .success(()):
//            do {
//                try verifiableAccount?.save { [weak self] _ in
//                    guard let me = self else {
//                        //Valid case: the view might be dismissed.
//                        return
//                    }
//                    DispatchQueue.main.async {
//                        me.delegate?.hideLoadingView()
//                        me.editableAccountSettingsDelegate?.didChange()
//                        me.delegate?.popViewController()
//                    }
//                }
//            } catch {
//                Log.shared.errorAndCrash(error: error)
//                delegate?.hideLoadingView()
//                delegate?.popViewController()
//            }
//        case .failure(let error):
//            delegate?.hideLoadingView()
//            if let imapError = error as? ImapSyncOperationError {
//                delegate?.showErrorAlert(error: imapError)
//            } else if let smtpError = error as? SmtpSendError {
//                delegate?.showErrorAlert(error: smtpError)
//            } else {
//                Log.shared.errorAndCrash(error: error)
//            }
//        }
    }
}

// MARK: -  enums & structs

extension EditableAccountSettingsViewModel2 {


    //MB:- Use it from AccountSettingsViewModel
    /// Identifies semantically the type of row.
//    public enum RowType : String {
//        case name
//        case email
//        case password
//        case signature
//        case includeInUnified
//        case pepSync
//        case reset
//        case server
//        case port
//        case tranportSecurity
//        case username
//        case oauth2Reauth
//    }

    public enum Transport {
        case plain
        case tls
        case startTls
    }

    public struct SecurityViewModel2 {
        var options = Server.Transport.toArray()
        var size : Int {
            get {
                return options.count
            }
        }

        subscript(option: Int) -> String {
            get {
                return options[option].asString()
            }
        }
    }
}

//extension EditableAccountSettingsViewModel2 {

    //MB:- Repeated. Use it from AccountSettingsViewModel
    /// Identifies the section in the table view.
//    public enum SectionType : String, CaseIterable {
//        case account
//        case imap
//        case smtp
//    }

    //MB:- Repeated. Use it from AccountSettingsViewModel
    /// Struct that represents a section in Account Settings View Controller
//    public struct Section {
//        /// Title of the section
//        var title: String
//        /// list of rows in the section
//        var rows: [AccountSettingsRowProtocol]
//        /// type of the section
//        var type: SectionType
//    }
//}

extension EditableAccountSettingsViewModel2 {
    //MB: - Change this. Need own cells.
    private struct CellsIdentifiers {
        static let oAuthCell = "oAuthTableViewCell"
        static let displayCell = "KeyValueTableViewCell"
        static let switchCell = "SwitchTableViewCell"
        static let dangerousCell = "DangerousTableViewCell"
        static let settingsCell = "settingsCell"
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

    /// This method return the corresponding title for each section.
    /// - Parameter type: The section type to choose the proper title.
    /// - Returns: The title for the requested section.
    private func sectionTitle(type: AccountSettingsViewModel.SectionType) -> String {
        switch type {
        case .account:
            return NSLocalizedString("Account", comment: "Tableview section  header: Account")
        case .imap:
            return NSLocalizedString("IMAP", comment: "Tableview section  header: IMAP")
        case .smtp:
            return NSLocalizedString("SMTP", comment: "Tableview section  header: IMAP")
        }
    }


    /// Generate and return the display row.
    /// - Parameters:
    ///   - type: The type of row.
    ///   - value: The value of the row.
    /// - Returns: The configured row.
    private func getDisplayRow(type : AccountSettingsViewModel.RowType, value : String) -> AccountSettingsViewModel.DisplayRow {
        return AccountSettingsViewModel.DisplayRow(type: type,
                                                   title: rowTitle(for: type),
                                                   text: value,
                                                   cellIdentifier: CellsIdentifiers.displayCell)
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


    //MB:-Repeteaded
    /// Provides the title of the row
    /// - Parameter type: The type of the row
    /// - Returns: the title of the row.
    private func rowTitle(for type : AccountSettingsViewModel.RowType) -> String {
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
        }
    }

}
