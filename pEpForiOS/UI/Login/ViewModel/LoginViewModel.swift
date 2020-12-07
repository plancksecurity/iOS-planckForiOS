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

final class LoginViewModel {
    /// If the last login attempt was via OAuth2, this will collect temporary parameters
    private var lastOAuth2Parameters: OAuth2Parameters?

    weak var accountVerificationResultDelegate: AccountVerificationResultDelegate?
    weak var loginViewModelLoginErrorDelegate: LoginViewModelLoginErrorDelegate?
    weak var loginViewModelOAuth2ErrorDelegate: LoginViewModelOAuth2ErrorDelegate?

    /// Holding both the data of the current account in verification,
    /// and also the implementation of the verification.
    var verifiableAccount: VerifiableAccountProtocol
    /// An OAuth2 process lives longer than the method call, so this object needs to survive.
    var currentOauth2Authorizer: OAuth2AuthorizationProtocol?
    /// Helper model to handle most of the OAuth2 authorization.
    var oauthAuthorizer = OAuthAuthorizer()
    var isAccountPEPSyncEnable = true {
        didSet {
            verifiableAccount.keySyncEnable = isAccountPEPSyncEnable
        }
    }

    public var shouldShowPasswordField: Bool {
           return !verifiableAccount.accountType.isOauth
    }

    let qualifyServerIsLocalService = QualifyServerIsLocalService()

    init(verifiableAccount: VerifiableAccountProtocol? = nil) {
        self.verifiableAccount =
            verifiableAccount ??
            VerifiableAccount.verifiableAccount(for: .other,
                                                usePEPFolderProvider: AppSettings.shared)
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

        oauthAuthorizer.delegate = self
        oauthAuthorizer.authorize(authorizer: oauth2Authorizer,
                                  emailAddress: emailAddress,
                                  accountType: verifiableAccount.accountType,
                                  viewController: viewController)
    }

    /// Depending on `VerifiableAccountProtocol.containsCompleteServerInfo`,
    /// either tries to retrive account settings via a query
    /// to the account settings lib, or procedes directly to attempting a login.
    /// - Parameters:
    ///   - emailAddres: The email of this account
    ///   - displayName: The chosen name of the user, or nick
    ///   - loginName: The optional login name for this account, if different from the email
    ///   - password: The password for the account
    ///   - accessToken: The access token for this account
    func login(emailAddress: String,
               displayName: String,
               loginName: String? = nil,
               password: String? = nil,
               accessToken: OAuth2AccessTokenProtocol? = nil) {
        if verifiableAccount.containsCompleteServerInfo {
            addVerificationData(verifiableAccount: verifiableAccount,
                                emailAddress: emailAddress,
                                displayName: displayName,
                                loginName: loginName,
                                password: password,
                                accessToken: accessToken)

            checkIfServerShouldBeConsideredATrustedServer()
        } else {
            loginViaAccountSettings(emailAddress: emailAddress,
                                    displayName: displayName,
                                    loginName: loginName,
                                    password: password,
                                    accessToken: accessToken)
        }
    }

    /// Tries to get login information via account settings, then continues with
    /// the account setup (login).
    /// - Parameters:
    ///   - emailAddress: The email of this account
    ///   - displayName: The chosen name of the user, or nick
    ///   - loginName: The optional login name for this account, if different from the email
    ///   - password: The password for the account
    ///   - accessToken: The access token for this account
    private func loginViaAccountSettings(emailAddress: String,
                                         displayName: String,
                                         loginName: String? = nil,
                                         password: String? = nil,
                                         accessToken: OAuth2AccessTokenProtocol? = nil) {
        let acSettings = AccountSettings(accountName: emailAddress,
                                         provider: nil,
                                         flags: AS_FLAG_USE_ANY,
                                         credentials: nil)
        acSettings.lookupCompletion() { settings in
            GCD.onMain() {
                libAccoutSettingsStatusOK()
            }
        }

        func libAccoutSettingsStatusOK() {
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
            let imapTransport = ConnectionTransport(accountSettingsTransport: incomingServer.transport,
                                                    imapPort: incomingServer.port)
            let smtpTransport = ConnectionTransport(accountSettingsTransport: outgoingServer.transport,
                                                    smtpPort: outgoingServer.port)

            addVerificationData(verifiableAccount: verifiableAccount,
                                emailAddress: emailAddress,
                                displayName: displayName,
                                loginName: loginName,
                                password: password,
                                accessToken: accessToken)

            verifiableAccount.serverIMAP = incomingServer.hostname
            verifiableAccount.portIMAP = UInt16(incomingServer.port)
            verifiableAccount.transportIMAP = imapTransport
            verifiableAccount.serverSMTP = outgoingServer.hostname
            verifiableAccount.portSMTP = UInt16(outgoingServer.port)
            verifiableAccount.transportSMTP = smtpTransport
            verifiableAccount.isAutomaticallyTrustedImapServer = false

            checkIfServerShouldBeConsideredATrustedServer()
        }
    }

    /// Set up a given verifiable account with parameters, changing it in-place.
    /// - Parameters:
    ///   - verifiableAccount: The verifiable account to change
    ///   - emailAddress: The email address of the account
    ///   - displayName: The user-chosen display name / nick
    ///   - loginName: The login name needed for the servers, if different from the email address
    ///   - password: The password to log in
    ///   - accessToken: An optional OAUTH2 access token
    private func addVerificationData(verifiableAccount: VerifiableAccountProtocol,
                                     emailAddress: String,
                                     displayName: String,
                                     loginName: String? = nil,
                                     password: String? = nil,
                                     accessToken: OAuth2AccessTokenProtocol? = nil) {
        var theVerifiableAccount = verifiableAccount

        // Note: auth method is never taken from LAS. We either have OAuth2,
        // as determined previously, or we will defer to pantomime to find out the best method.
        theVerifiableAccount.authMethod = accessToken != nil ? .saslXoauth2 : nil

        theVerifiableAccount.verifiableAccountDelegate = self
        theVerifiableAccount.address = emailAddress
        theVerifiableAccount.userName = displayName

        let login = loginName ?? emailAddress
        theVerifiableAccount.loginNameIMAP = login
        theVerifiableAccount.loginNameSMTP = login

        theVerifiableAccount.password = password
        theVerifiableAccount.accessToken = accessToken

        theVerifiableAccount.verifiableAccountDelegate = self
    }
}

// MARK: - Private

extension LoginViewModel {

    private func checkIfServerShouldBeConsideredATrustedServer() {
        if let imapServer = verifiableAccount.serverIMAP {
            qualifyServerIsLocalService.delegate = self
            qualifyServerIsLocalService.qualify(serverName: imapServer)
        } else {
            markServerAsTrusted(trusted: false)
        }
    }

    private func markServerAsTrusted(trusted: Bool) {
        verifiableAccount.isAutomaticallyTrustedImapServer = trusted
        do {
            try verifiableAccount.verify()
        } catch {
            Log.shared.error("%@", "\(error)")
            loginViewModelLoginErrorDelegate?.handle(loginError: error)
        }
    }
}

// MARK: - OAuthAuthorizerDelegate

extension LoginViewModel: OAuthAuthorizerDelegate {
    func didAuthorize(oauth2Error: Error?, accessToken: OAuth2AccessTokenProtocol?) {
        if let err = oauth2Error {
            loginViewModelOAuth2ErrorDelegate?.handle(oauth2Error: err)
        } else {
            if let token = accessToken {
                guard let oauth2Params = lastOAuth2Parameters else {
                    loginViewModelOAuth2ErrorDelegate?.handle(
                        oauth2Error: OAuthAuthorizerError.noParametersForVerification)
                    return
                }
                login(emailAddress: oauth2Params.emailAddress,
                      displayName: oauth2Params.userName,
                      accessToken: token)
            } else {
                loginViewModelOAuth2ErrorDelegate?.handle(
                    oauth2Error: OAuthAuthorizerError.noToken)
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
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            if let err = error {
                self?.loginViewModelLoginErrorDelegate?.handle(loginError: err)
                return
            }
            me.markServerAsTrusted(trusted: isLocal ?? false)
        }
    }
}

// MARK: - VerifiableAccountDelegate

extension LoginViewModel: VerifiableAccountDelegate {
    func informAccountVerificationResultDelegate(error: Error? = nil) {
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
        case .success:
            verifiableAccount.save { [weak self] (result) in
                guard let me = self else {
                    Log.shared.errorAndCrash("Lost MySelf")
                    return
                }
                switch result {
                case .success:
                    me.informAccountVerificationResultDelegate()
                case .failure(let error):
                    me.informAccountVerificationResultDelegate(error: error)
                }
            }
        case .failure(let error):
            informAccountVerificationResultDelegate(error: error)
        }
    }
}
