//
//  LoginLogic.swift
//  pEp
//
//  Created by Sascha Bacardit on 3/3/23.
//  Copyright © 2023 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel
import pEpIOSToolbox

import PantomimeFramework
class LoginHandler {
    weak var loginProtocolResponseDelegate: LoginProtocolResponseDelegate?

    /// Holding both the data of the current account in verification,
    /// and also the implementation of the verification.
    var verifiableAccount = VerifiableAccount.verifiableAccount(for: .other,
                                                                usePEPFolderProvider: AppSettings.shared)

    /// An OAuth2 process lives longer than the method call, so this object needs to survive.
    var currentOauth2Authorizer: OAuth2AuthorizationProtocol?
    /// Helper model to handle most of the OAuth2 authorization.
    var oauthAuthorizer = OAuthAuthorizer()
    var isAccountPEPSyncEnable = true {
        didSet {
            verifiableAccount.keySyncEnable = isAccountPEPSyncEnable
        }
    }

    let qualifyServerIsLocalService = QualifyServerIsLocalService()

    init(verifiableAccount: VerifiableAccountProtocol? = nil) {
        if (verifiableAccount != nil){
            self.verifiableAccount=verifiableAccount!
        }
    }
}
// MARK: - Private

extension LoginHandler {
    /// Depending on `VerifiableAccountProtocol.containsCompleteServerInfo`,
    /// either tries to retrive account settings via a query
    /// to the account settings lib, or procedes directly to attempting a login.
    /// - Parameters:
    ///   - emailAddres: The email of this account
    ///   - displayName: The chosen name of the user, or nick
    ///   - loginName: The optional login name for this account, if different from the email
    ///   - password: The password for the account
    ///   - accessToken: The access token for this account
    private func startLogin(emailAddress: String,
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
            DispatchQueue.main.async {
                libAccoutSettingsStatusOK()
            }
        }

        func libAccoutSettingsStatusOK() {
            if let error = AccountSettings.AccountSettingsError(accountSettings: acSettings) {
                Log.shared.log(error: error)
                loginProtocolResponseDelegate?.didFail(error: error)
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

        // Use the same password for imap and smtp when the user attemps to login in the first screen of the flow.
        // If login fails, the user will be prompt to enter those passwords separately.
        theVerifiableAccount.imapPassword = password
        theVerifiableAccount.smtpPassword = password
        theVerifiableAccount.accessToken = accessToken

        theVerifiableAccount.verifiableAccountDelegate = self
    }
    private func checkIfServerShouldBeConsideredATrustedServer() {
        if let imapServer = verifiableAccount.serverIMAP {
            qualifyServerIsLocalService.delegate = self
            qualifyServerIsLocalService.qualify(serverName: imapServer)
        } else {
            markServerAsTrusted(trusted: true)
        }
    }

    private func markServerAsTrusted(trusted: Bool) {
        verifiableAccount.isAutomaticallyTrustedImapServer = trusted
        do {
            try verifiableAccount.verify()
        } catch {
            Log.shared.log(error: error)
            loginProtocolResponseDelegate?.didFail(error: error)
        }
    }

    
}

// MARK: - OAuthAuthorizerDelegate

extension LoginHandler: OAuthAuthorizerDelegate {
    func didAuthorize(oauth2Error: Error?, accessToken: OAuth2AccessTokenProtocol?) {
        if let err = oauth2Error {
            loginProtocolResponseDelegate?.didFail(error: err)
        } else {
            if let token = accessToken {
                if let email = token.authState.getEmail(), let name = token.authState.getName(){
                    startLogin(emailAddress: email,
                          displayName: name,
                          accessToken: token)
                } else {
                    loginProtocolResponseDelegate?.didFail(
                        error: OAuthAuthorizerError.noToken)
                }
            } else {
                loginProtocolResponseDelegate?.didFail(
                    error: OAuthAuthorizerError.noToken)
            }
        }
        currentOauth2Authorizer = nil
    }
}

// MARK: - LoginProtocol

extension LoginHandler: loginprotocol {
    func initialize(loginProtocolErrorDelegate: LoginProtocolResponseDelegate) {
        self.loginProtocolResponseDelegate = loginProtocolErrorDelegate
    }

    //Login via usrname+password
    func login(emailAddress: String,
               displayName: String,
               password: String){
        startLogin(emailAddress: emailAddress,
                   displayName: displayName,
                   password: password)
    }
    //login via OAuth
    func loginWithOAuth2(
        viewController: UIViewController){
            oauthAuthorizer.delegate = self
            let oauth2Authorizer = OAuth2ProviderFactory().oauth2Provider().createOAuth2Authorizer()

            oauthAuthorizer.authorize(authorizer: oauth2Authorizer,
                                      accountType: verifiableAccount.accountType,
                                      viewController: viewController)
        }
}

// MARK: - QualifyServerIsLocalServiceDelegate

extension LoginHandler: QualifyServerIsLocalServiceDelegate {
    func didQualify(serverName: String, isLocal: Bool?, error: Error?) {
        DispatchQueue.main.async { [weak self] in
            guard let me = self else {
                Log.shared.lostMySelf()
                return
            }
            if let err = error {
                self?.loginProtocolResponseDelegate?.didFail(error: err)
                return
            }
            me.markServerAsTrusted(trusted: isLocal ?? false)
        }
    }
}

// MARK: - VerifiableAccountDelegate

extension LoginHandler: VerifiableAccountDelegate {
    func informAccountVerificationResultDelegate(error: Error? = nil) {
        if let imapError = error as? ImapSyncOperationError {
            loginProtocolResponseDelegate?.didVerify(
                result: .imapError(imapError))
        } else if let smtpError = error as? SmtpSendError {
            loginProtocolResponseDelegate?.didVerify(
                result: .smtpError(smtpError))
        } else {
            if let theError = error {
                Log.shared.errorAndCrash(error: theError)
            } else {
                loginProtocolResponseDelegate?.didVerify(result: .ok)
            }
        }
    }

    func didEndVerification(result: Result<Void, Error>) {
        switch result {
        case .success:
            verifiableAccount.save { [weak self] (result) in
                guard let me = self else {
                // Valid case. We might have been dismissed already.
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
