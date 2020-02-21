//
//  LoginViewModel.swift
//  pEpForiOS
//
//  Created by Xavier Algarra on 26/04/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel
import pEpIOSToolbox
import PantomimeFramework

// MARK: - AccountType

extension LoginViewModel {
    //Remove when account type is mgerge
    //TODO: Xavia this enum is in Account selector view model, this is just a place holder. Remove it and use yours. (from alejandro, andreas assumes he means Xavier)
    enum AccountType {
        case gmail
        case clientCertificate
        case other

        var isOauth: Bool {
            return self != .other
        }
    }
}

// MARK: - LoginCellType

extension LoginViewModel {
    enum LoginCellType {
        case Text, Button
    }
}

// MARK: - OAuth2Parameters

extension LoginViewModel {
    struct OAuth2Parameters {
        let emailAddress: String
        let userName: String
    }
}

class LoginViewModel {
    weak var accountVerificationResultDelegate: AccountVerificationResultDelegate?
    weak var loginViewModelLoginErrorDelegate: LoginViewModelLoginErrorDelegate?
    weak var loginViewModelOAuth2ErrorDelegate: LoginViewModelOAuth2ErrorDelegate?

    /// Holding both the data of the current account in verification,
    /// and also the implementation of the verification.
    var verifiableAccount: VerifiableAccountProtocol
    /// An OAuth2 process lives longer than the method call, so this object needs to survive.
    var currentOauth2Authorizer: OAuth2AuthorizationProtocol?
    /// Helper model to handle most of the OAuth2 authorization.
    var oauth2Model = OAuth2AuthViewModel()
    var isAccountPEPSyncEnable = true {
        didSet {
            verifiableAccount.keySyncEnable = isAccountPEPSyncEnable
        }
    }

    /// If the last login attempt was via OAuth2, this will collect temporary parameters
    private var lastOAuth2Parameters: OAuth2Parameters?

    let qualifyServerService = QualifyServerIsLocalService()

    init(verifiableAccount: VerifiableAccountProtocol) {
        self.verifiableAccount = verifiableAccount
    }

    func isThereAnAccount() -> Bool {
        return !Account.all().isEmpty
    }

    func exist(address: String) -> Bool {
        return Account.by(address: address) != nil
    }

    func loginWithOAuth2(
        viewController: UIViewController,
        emailAddress: String,
        userName: String,
        oauth2Authorizer: OAuth2AuthorizationProtocol) {
        lastOAuth2Parameters = OAuth2Parameters(emailAddress: emailAddress,
                                                userName: userName)

        oauth2Model.delegate = self
        oauth2Model.authorize(authorizer: oauth2Authorizer,
                              emailAddress: emailAddress,
                              viewController: viewController)
    }

    /// Tries to "login", that is, retrieve account data, with the given parameters.
    /// - Parameters:
    ///   - emailAddres: The email of this account
    ///   - displayName: The chosen name of the user, or nick
    ///   - loginName: The optional login name for this account, if different from the email
    ///   - password: The password for the account
    ///   - accessToken: The access token for this account
    func login(emailAddress: String, displayName: String, loginName: String? = nil,
               password: String? = nil, accessToken: OAuth2AccessTokenProtocol? = nil) {
        let acSettings = AccountSettings(accountName: emailAddress, provider: nil,
                                         flags: AS_FLAG_USE_ANY, credentials: nil)
        acSettings.lookupCompletion() { [weak self] settings in
            GCD.onMain() {
                statusOk()
            }
        }

        func statusOk() {
            if let error = AccountSettings.AccountSettingsError(accountSettings: acSettings) {
                Log.shared.error("%@", "\(error)")
                loginViewModelLoginErrorDelegate?.handle(loginError: error)
                return
            }

            guard let incomingServer = acSettings.incoming,
                let outgoingServer = acSettings.outgoing else {
                    // AccountSettingsError() already handled the error
                    return
            }
            let imapTransport = ConnectionTransport(
                accountSettingsTransport: incomingServer.transport, imapPort: incomingServer.port)
            let smtpTransport = ConnectionTransport(
                accountSettingsTransport: outgoingServer.transport, smtpPort: outgoingServer.port)

            verifiableAccount.verifiableAccountDelegate = self
            verifiableAccount.address = emailAddress
            verifiableAccount.userName = displayName

            let login = loginName ?? emailAddress
            verifiableAccount.loginNameIMAP = login
            verifiableAccount.loginNameSMTP = login

            // Note: auth method is never taken from LAS. We either have OAuth2,
            // as determined previously, or we will defer to pantomime to find out the best method.
            verifiableAccount.authMethod = accessToken != nil ? .saslXoauth2 : nil

            verifiableAccount.password = password
            verifiableAccount.accessToken = accessToken
            verifiableAccount.serverIMAP = incomingServer.hostname
            verifiableAccount.portIMAP = UInt16(incomingServer.port)
            verifiableAccount.transportIMAP = imapTransport
            verifiableAccount.serverSMTP = outgoingServer.hostname
            verifiableAccount.portSMTP = UInt16(outgoingServer.port)
            verifiableAccount.transportSMTP = smtpTransport
            verifiableAccount.isAutomaticallyTrustedImapServer = false

            verifyAccount(model: verifiableAccount)
        }
    }

    /// Creates and persits an account with given data and triggers a verification request.
    ///
    /// - Parameter model: account data
    /// - Throws: AccountVerificationError
    func verifyAccount(model: VerifiableAccountProtocol?) {
        if let imapServer = verifiableAccount.serverIMAP {
            qualifyServerService.delegate = self
            qualifyServerService.qualify(serverName: imapServer)
        } else {
            accountHasBeenQualified(trusted: false)
        }
    }

    func accountHasBeenQualified(trusted: Bool) {
        verifiableAccount.isAutomaticallyTrustedImapServer = trusted
        do {
            try verifiableAccount.verify()
        } catch {
            Log.shared.error("%@", "\(error)")
            loginViewModelLoginErrorDelegate?.handle(loginError: error)
        }
    }

    /// Is an account with this email address typically an OAuth2 account?
    /// Only uses fast local lookups.
    /// - Parameter email: Returns true, if this is an OAuth2 email address, true otherwise.
    func isOAuth2Possible(email: String?) -> Bool {
        return AccountSettings.quickLookUp(emailAddress: email)?.supportsOAuth2 ?? false
    }
}

// MARK: - OAuth2AuthViewModelDelegate

extension LoginViewModel: OAuth2AuthViewModelDelegate {
    func didAuthorize(oauth2Error: Error?, accessToken: OAuth2AccessTokenProtocol?) {
        if let err = oauth2Error {
            loginViewModelOAuth2ErrorDelegate?.handle(oauth2Error: err)
        } else {
            if let token = accessToken {
                guard let oauth2Params = lastOAuth2Parameters else {
                    loginViewModelOAuth2ErrorDelegate?.handle(
                        oauth2Error: OAuth2AuthViewModelError.noParametersForVerification)
                    return
                }
                login(emailAddress: oauth2Params.emailAddress,
                      displayName: oauth2Params.userName,
                      accessToken: token)
            } else {
                loginViewModelOAuth2ErrorDelegate?.handle(
                    oauth2Error: OAuth2AuthViewModelError.noToken)
            }
        }
        lastOAuth2Parameters = nil
        currentOauth2Authorizer = nil
    }
}

// MARK: - QualifyServerIsLocalServiceDelegate

extension LoginViewModel: QualifyServerIsLocalServiceDelegate {
    func didQualify(serverName: String, isLocal: Bool?, error: Error?) {
        GCD.onMain { [weak self] in
            if let err = error {
                self?.loginViewModelLoginErrorDelegate?.handle(loginError: err)
            }
            self?.accountHasBeenQualified(trusted: isLocal ?? false)
        }
    }
}

// MARK: - VerifiableAccountDelegate

extension LoginViewModel: VerifiableAccountDelegate {
    func informAccountVerificationResultDelegate(error: Error?) {
        if let imapError = error as? ImapSyncOperationError {
            accountVerificationResultDelegate?.didVerify(
                result: .imapError(imapError))
        } else if let smtpError = error as? SmtpSendError {
            accountVerificationResultDelegate?.didVerify(
                result: .smtpError(smtpError))
        } else {
            if let theError = error {
                Log.shared.errorAndCrash(error: theError)
            } else {
                accountVerificationResultDelegate?.didVerify(result: .ok)
            }
        }
    }

    func didEndVerification(result: Result<Void, Error>) {
        switch result {
        case .success(()):
            do {
                try verifiableAccount.save() { [weak self] success in
                    guard let me = self else {
                        Log.shared.errorAndCrash("Lost MySelf")
                        return
                    }
                    me.informAccountVerificationResultDelegate(error: nil)
                }
            } catch {
                Log.shared.errorAndCrash(error: error)
            }
        case .failure(let error):
            informAccountVerificationResultDelegate(error: error)
        }
    }
}
