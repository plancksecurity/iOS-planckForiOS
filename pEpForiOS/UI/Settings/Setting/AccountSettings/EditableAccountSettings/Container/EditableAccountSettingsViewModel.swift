//
//  EditableAccountSettingsViewModel.swift
//  pEp
//
//  Created by Alejandro Gelos on 08/10/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel
import pEpIOSToolbox
import PantomimeFramework

protocol EditableAccountSettingsViewModelDelegate: class {
    func showErrorAlert(error: Error)
    func showLoadingView()
    func hideLoadingView()
    func popViewController()
}

protocol EditableAccountSettingsDelegate: class {
    func didChange()
}

final class EditableAccountSettingsViewModel {
    typealias Inputs = (addrImap: String, portImap: String, transImap: String,
    addrSmpt: String, portSmtp: String, transSmtp: String, accountName: String,
    imapUsername: String, smtpUsername: String)

    var account: Account
    var isOAuth2: Bool {
        return account.imapServer?.authMethod == AuthMethod.saslXoauth2.rawValue
    }

    var password: String? {
        guard let tableViewModel = tableViewModel else {
            Log.shared.errorAndCrash("Founded nil tableViewModel in EditableAccountSettingsViewModel")
            return nil
        }
        return tableViewModel.passwordChanged ? tableViewModel.password : nil
    }

    /// Holding both the data of the current account in verification,
    /// and also the implementation of the verification.
    var verifiableAccount: VerifiableAccountProtocol?
    var passwordChanged = false

    weak var delegate: EditableAccountSettingsViewModelDelegate?
    weak var tableViewModel: EditableAccountSettingsTableViewModel?
    weak var editableAccountSettingsDelegate: EditableAccountSettingsDelegate?

    /// If there was OAUTH2 for this account, here is a current token.
    /// This trumps both the `originalPassword` and a password given by the user
    /// via the UI.
    /// - Note: For logins that require it, there must be an up-to-date token
    ///         for the verification be able to succeed.
    ///         It is extracted from the existing server credentials on `init`.
    private var accessToken: OAuth2AccessTokenProtocol?

    init(account: Account, editableAccountSettingsDelegate: EditableAccountSettingsDelegate? = nil) {
        self.account = account
        self.editableAccountSettingsDelegate = editableAccountSettingsDelegate

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
    }

    func handleSaveButton() {
        delegate?.showLoadingView()
        do {
            let validated = try validateInputs()
            let imap = ServerViewModel(address: validated.addrImap,
                                       port: validated.portImap,
                                       transport: validated.transImap)
            let smtp = ServerViewModel(address: validated.addrSmpt,
                                       port: validated.portSmtp,
                                       transport: validated.transSmtp)
            update(imapUsername: validated.imapUsername, smtpUsername: validated.smtpUsername, name: validated.accountName,
                   password: password, imap: imap, smtp: smtp)
        } catch {
            delegate?.hideLoadingView()
            delegate?.showErrorAlert(error: error)
        }
    }
}

// MARK: - VerifiableAccountDelegate

extension EditableAccountSettingsViewModel: VerifiableAccountDelegate {
    func didEndVerification(result: Result<Void, Error>) {
        switch result {
        case .success(()):
            do {
                try verifiableAccount?.save { [weak self] _ in
                    guard let me = self else {
                        //Valid case: the view might be dismissed. 
                        return
                    }
                    DispatchQueue.main.async {
                        me.delegate?.hideLoadingView()
                        me.editableAccountSettingsDelegate?.didChange()
                        me.delegate?.popViewController()
                    }
                }
            } catch {
                Log.shared.errorAndCrash(error: error)
                delegate?.hideLoadingView()
                delegate?.popViewController()
            }
        case .failure(let error):
            delegate?.hideLoadingView()
            if let imapError = error as? ImapSyncOperationError {
                delegate?.showErrorAlert(error: imapError)
            } else if let smtpError = error as? SmtpSendError {
                delegate?.showErrorAlert(error: smtpError)
            } else {
                Log.shared.errorAndCrash(error: error)
            }
        }
    }
}

// MARK: - Private

extension EditableAccountSettingsViewModel {

    private func validateInputs() throws -> Inputs {
            //Validate all inputs, so far only tableViewModel
            guard let tableViewModel = tableViewModel else {
                Log.shared.errorAndCrash("No VM")
                throw SettingsInternalError.nilViewModel
            }
            return try tableViewModel.validateInputs()
    }

    private func update(imapUsername: String,
                        smtpUsername: String,
                        name: String,
                        password: String? = nil,
                        imap: ServerViewModel,
                        smtp: ServerViewModel) {
        var theVerifier =
            verifiableAccount ??
            VerifiableAccount.verifiableAccount(for: .other)
        theVerifier.verifiableAccountDelegate = self
        verifiableAccount = theVerifier

        theVerifier.address = tableViewModel?.email
        theVerifier.userName = name
        theVerifier.loginNameIMAP = imapUsername
        theVerifier.loginNameSMTP = smtpUsername

        if isOAuth2 {
            if self.accessToken == nil {
                Log.shared.errorAndCrash("Have to do OAUTH2, but lacking current token")
            }
            theVerifier.authMethod = .saslXoauth2
            theVerifier.accessToken = accessToken
            // OAUTH2 trumps any password
            theVerifier.password = nil
        } else {
            theVerifier.password = tableViewModel?.originalPassword
            if password != nil {
                theVerifier.password = password
            }
        }

        // IMAP
        theVerifier.serverIMAP = imap.address
        if let portString = imap.port, let port = UInt16(portString) {
            theVerifier.portIMAP = port
        }
        if let transport = Server.Transport(fromString: imap.transport) {
            theVerifier.transportIMAP = ConnectionTransport(transport: transport)
        }

        // SMTP
        theVerifier.serverSMTP = smtp.address
        if let portString = smtp.port, let port = UInt16(portString) {
            theVerifier.portSMTP = port
        }
        if let transport = Server.Transport(fromString: smtp.transport) {
            theVerifier.transportSMTP = ConnectionTransport(transport: transport)
        }

        do {
            try theVerifier.verify()
        } catch {
            delegate?.hideLoadingView()
            delegate?.showErrorAlert(error: LoginViewController.LoginError.noConnectData)
        }
    }
}

// MARK: - Helping structures

extension EditableAccountSettingsViewModel {
    struct ServerViewModel {
        var address: String?
        var port: String?
        var transport: String?
    }
}
