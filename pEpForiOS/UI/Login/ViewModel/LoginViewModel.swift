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

enum LoginCellType {
    case Text, Button
}

class LoginViewModel {
    struct OAuth2Parameters {
        let emailAddress: String
        let userName: String
        let mySelfer: KickOffMySelfProtocol
    }

    /// Holding both the data of the current account in verification,
    /// and also the implementation of the verification.
    var verificationService: VerifiableAccountProtocol?

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
     Helper model to handle most of the OAuth2 authorization.
     */
    var oauth2Model = OAuth2AuthViewModel()

    let qualifyServerService = QualifyServerIsLocalService()

    init(verificationService: VerifiableAccountProtocol? = nil) {
        self.verificationService = verificationService
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
                Log.shared.error("%{public}@", error.localizedDescription)
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

            var newAccount = verificationService ?? VerifiableAccount()

            newAccount.verifiableAccountDelegate = self
            newAccount.address = accountName
            newAccount.userName = userName
            newAccount.loginName = loginName

            // Note: auth method is never taken from LAS. We either have OAuth2,
            // as determined previously, or we will defer to pantomime to find out the best method.
            newAccount.authMethod = accessToken != nil ? .saslXoauth2 : nil

            newAccount.password = password
            newAccount.accessToken = accessToken
            newAccount.serverIMAP = incomingServer.hostname
            newAccount.portIMAP = UInt16(incomingServer.port)
            newAccount.transportIMAP = imapTransport
            newAccount.serverSMTP = outgoingServer.hostname
            newAccount.portSMTP = UInt16(outgoingServer.port)
            newAccount.transportSMTP = smtpTransport
            newAccount.trustedImapServer = false

            verificationService = newAccount
            verifyAccount(model: newAccount)
        }
    }

    /// Creates and persits an account with given data and triggers a verification request.
    ///
    /// - Parameter model: account data
    /// - Throws: AccountVerificationError
    func verifyAccount(model: VerifiableAccountProtocol?) {
        if let imapServer = verificationService?.serverIMAP {
            qualifyServerService.delegate = self
            qualifyServerService.qualify(serverName: imapServer)
        } else {
            accountHasBeenQualified(trusted: false)
        }
    }

    func accountHasBeenQualified(trusted: Bool) {
        guard var theVerificationService = verificationService else {
            Log.shared.errorAndCrash("no VerificationService")
            return
        }

        theVerificationService.trustedImapServer = trusted
        do {
            try theVerificationService.verify()
        } catch {
            Log.shared.error("%{public}@", error.localizedDescription)
            loginViewModelLoginErrorDelegate?.handle(loginError: error)
        }
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
                      accessToken: token, mySelfer: oauth2Params.mySelfer)
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
        guard let theService = verificationService else {
            Log.shared.error(
                "Lost the verificationService, was about to inform the delegate")
            if let err = error {
                Log.shared.log("%@", err.localizedDescription)
            }
            return
        }
        if let imapError = error as? ImapSyncError {
            accountVerificationResultDelegate?.didVerify(
                result: .imapError(imapError), accountInput: theService)
        } else if let smtpError = error as? SmtpSendError {
            accountVerificationResultDelegate?.didVerify(
                result: .smtpError(smtpError), accountInput: theService)
        } else {
            if let theError = error {
                Log.shared.errorAndCrash("%@", theError.localizedDescription)
            } else {
                accountVerificationResultDelegate?.didVerify(result: .ok, accountInput: theService)
            }
        }
    }

    func didEndVerification(result: Result<Void, Error>) {
        switch result {
        case .success(()):
            do {
                try verificationService?.save()
                informAccountVerificationResultDelegate(error: nil)
                mySelfer?.startMySelf()
            } catch {
                Log.shared.errorAndCrash("%@", error.localizedDescription)
            }
        case .failure(let error):
            informAccountVerificationResultDelegate(error: error)
        }
    }
}
