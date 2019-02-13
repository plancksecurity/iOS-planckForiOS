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

enum LoginCellType {
    case Text, Button
}

class LoginViewModel {
    struct OAuth2Parameters {
        let emailAddress: String
        let userName: String
        let mySelfer: KickOffMySelfProtocol
    }

    var loginAccount: Account?
    var messageSyncService: MessageSyncServiceProtocol?

    /** If the last login attempt was via OAuth2, this will collect temporary parameters */
    private var lastOAuth2Parameters: OAuth2Parameters?

    weak var accountVerificationResultDelegate: AccountVerificationResultDelegate?
    weak var loginViewModelLoginErrorDelegate: LoginViewModelLoginErrorDelegate?
    weak var loginViewModelOAuth2ErrorDelegate: LoginViewModelOAuth2ErrorDelegate?

    /**
     The last mySelfer, as indicated by login(), so after account verification,
     a key can be generated.
     */
    var mySelfer: KickOffMySelfProtocol?

    /**
     An OAuth2 process lives longer than the method call, so this object needs to survive.
     */
    var currentOauth2Authorizer: OAuth2AuthorizationProtocol?

    /**
     The most current account in verification.
     */
    var accountInVerification: AccountUserInput?

    /**
     Helper model to handle most of the OAuth2 authorization.
     */
    var oauth2Model = OAuth2AuthViewModel()

    let qualifyServerService = QualifyServerIsLocalService()

    init(messageSyncService: MessageSyncServiceProtocol? = nil) {
        self.messageSyncService = messageSyncService
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
        mySelfer: KickOffMySelfProtocol,
        oauth2Authorizer: OAuth2AuthorizationProtocol) {
        lastOAuth2Parameters = OAuth2Parameters(
            emailAddress: emailAddress, userName: userName, mySelfer: mySelfer)

        oauth2Model.delegate = self
        oauth2Model.authorize(authorizer: oauth2Authorizer, emailAddress: emailAddress,
                              viewController: viewController)
    }

    /**
     Tries to "login", that is, retrieve account data, with the given parameters.
     - parameter accountName: The email of this account
     - parameter password: The password for the account
     - parameter loginName: The optional login name for this account, if different from the email
     - parameter userName: The chosen name of the user, or nick
     - parameter mySelfer: An object to request a mySelf operation from, must be used immediately
     after account setup
     */
    func login(accountName: String, userName: String, loginName: String? = nil,
               password: String? = nil, accessToken: OAuth2AccessTokenProtocol? = nil,
               mySelfer: KickOffMySelfProtocol) {
        self.mySelfer = mySelfer
        let acSettings = AccountSettings(accountName: accountName, provider: nil,
                                         flags: AS_FLAG_USE_ANY, credentials: nil)
        acSettings.lookupCompletion() { [weak self] settings in
            GCD.onMain() {
                statusOk()
            }
        }

        func statusOk() {
            if let error = AccountSettings.AccountSettingsError(accountSettings: acSettings) {
                Logger.frontendLogger.error("%{public}@", error.localizedDescription)
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

            // Note: auth method is never taken from LAS. We either have OAuth2,
            // as determined previously, or we will defer to pantomime to find out the best method.
            let newAccount = AccountUserInput(
                address: accountName, userName: userName,
                loginName: loginName,
                authMethod: accessToken != nil ? .saslXoauth2 : nil,
                password: accessToken == nil ? password : nil,
                accessToken: accessToken,
                serverIMAP: incomingServer.hostname,
                portIMAP: UInt16(incomingServer.port),
                transportIMAP: imapTransport,
                serverSMTP: outgoingServer.hostname,
                portSMTP: UInt16(outgoingServer.port),
                transportSMTP: smtpTransport)
            accountInVerification = newAccount

            do {
                try verifyAccount(model: newAccount)
            } catch {
                Logger.frontendLogger.error("%{public}@", error.localizedDescription)
                loginViewModelLoginErrorDelegate?.handle(loginError: error)
            }
        }
    }

    /// Creates and persits an account with given data and triggers a verification request.
    ///
    /// - Parameter model: account data
    /// - Throws: AccountVerificationError
    func verifyAccount(model: AccountUserInput) throws {
        do {
            let account = try model.account()
            loginAccount = account // have to store that for callback use

            if let imapServer = account.imapServer?.address {
                qualifyServerService.delegate = self
                qualifyServerService.qualify(serverName: imapServer)
            } else {
                accountHasBeenQualified(trusted: false)
            }
        } catch {
            throw error
        }
    }

    func accountHasBeenQualified(trusted: Bool) {
        guard let ms = messageSyncService else {
            Logger.frontendLogger.errorAndCrash("no MessageSyncService")
            return
        }
        guard let account = loginAccount else {
            Logger.frontendLogger.errorAndCrash("have lost loginAccount")
            return
        }
        account.imapServer?.trusted = trusted
        ms.requestVerification(account: account, delegate: self)
    }

    /**
     Is an account with this email address typically an OAuth2 account?
     Only uses fast local lookups.
     - Returns true, if this is an OAuth2 email address, true otherwise.
     */
    func isOAuth2Possible(email: String?) -> Bool {
        return AccountSettings.quickLookUp(emailAddress: email)?.supportsOAuth2 ?? false
    }
}

// MARK: - AccountVerificationServiceDelegate

extension LoginViewModel: AccountVerificationServiceDelegate {
    func verified(account: Account,
                  service: AccountVerificationServiceProtocol,
                  result: AccountVerificationResult) {
        if result == .ok {
            //remove obsolete code on EmailListViewController
            MessageModel.performAndWait {
                account.save()
            }
            mySelfer?.startMySelf()
        }
        accountVerificationResultDelegate?.didVerify(result: result,
                                                     accountInput: accountInVerification)
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
                login(accountName: oauth2Params.emailAddress, userName: oauth2Params.userName,
                      accessToken: accessToken, mySelfer: oauth2Params.mySelfer)
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
