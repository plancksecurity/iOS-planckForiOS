//
//  LoginViewModel.swift
//  pEpForiOS
//
//  Created by Xavier Algarra on 26/04/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel

enum AccountSettingsError: Error {
    case timeOut
    case notFound
    case illegalValue

    init?(accountSettings: AccountSettingsProtocol) {
        switch accountSettings.status {
        case AS_TIMEOUT:
            self = .timeOut
        case AS_NOT_FOUND:
            self = .notFound
        case AS_ILLEGAL_VALUE:
            self = .illegalValue
        default:
            if let _ = accountSettings.outgoing, let _ = accountSettings.incoming {
                return nil
            } else {
                self = .notFound
            }
        }
    }
}

/**
 Errors that are not directly reported by the used OAuth2 lib, but detected internally.
 */
enum OAuth2InternalError: Error {
    /**
     No configuration available for running the oauth2 request.
     */
    case noConfiguration

    /**
     The OAuth2 call yielded no token, but there was no error condition
     */
    case noToken

    /**
     The OAuth2 authorization was successful, but we lack the `lastOAuth2Parameters`
     for continuing login.
     */
    case noParametersForVerification
}

extension AccountSettingsError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .timeOut:
            return NSLocalizedString("Account detection timed out",
                                     comment: "Error description detecting account settings")
        case .notFound, .illegalValue:
            return NSLocalizedString("Could not find servers",
                                     comment: "Error description detecting account settings")
        }
    }
}

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

        var theAuth = oauth2Authorizer
        theAuth.delegate = self

        // Determine oauth2 configuration
        var config: OAuth2ConfigurationProtocol?
        if emailAddress.isGmailAddress {
            config = OAuth2Type.google.oauth2Config()
        } else if emailAddress.isYahooAddress {
            config = OAuth2Type.yahoo.oauth2Config()
        }
        if let theConfig = config {
            currentOauth2Authorizer = oauth2Authorizer
            theAuth.startAuthorizationRequest(
                viewController: viewController, oauth2Configuration: theConfig)
        } else {
            authorizationRequestFinished(error: OAuth2InternalError.noConfiguration,
                                         accessToken: nil)
        }
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
            if let error = AccountSettingsError(accountSettings: acSettings) {
                Log.shared.error(component: #function, error: error)
                loginViewModelLoginErrorDelegate?.handle(loginError: error)
                return
            }

            guard let incomingServer = acSettings.incoming,
                let outgoingServer = acSettings.outgoing else {
                    // AccountSettingsError() already handled the error
                    return
            }
            let imapTransport = ConnectionTransport(
                accountSettingsTransport: incomingServer.transport)
            let smtpTransport = ConnectionTransport(
                accountSettingsTransport: outgoingServer.transport)

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

            do {
                try verifyAccount(model: newAccount)
            } catch {
                Log.shared.error(component: #function, error: error)
                loginViewModelLoginErrorDelegate?.handle(loginError: error)
            }
        }
    }

    /// Creates and persits an account with given data and triggers a verification request.
    ///
    /// - Parameter model: account data
    /// - Throws: AccountVerificationError
    func verifyAccount(model: AccountUserInput) throws {
        guard let ms = messageSyncService else {
            Log.shared.errorAndCrash(component: #function, errorString: "no MessageSyncService")
            return
        }
        do {
            let account = try model.account()
            loginAccount = account
            account.needsVerification = true
            account.save()
            ms.requestVerification(account: account, delegate: self)
        } catch {
            throw error
        }
    }

    /**
     Is an account with this email address typically an OAuth2 account?
     - Returns true, if this is an OAuth2 email address, true otherwise.
     */
    func isOAuth2Possible(email: String?) -> Bool {
        if let theMail = email?.trimmedWhiteSpace() {
            return theMail.isGmailAddress || theMail.isYahooAddress
        } else {
            return false
        }
    }
}

// MARK: - AccountVerificationServiceDelegate

extension LoginViewModel: AccountVerificationServiceDelegate {
    func verified(account: Account, service: AccountVerificationServiceProtocol,
                  result: AccountVerificationResult) {
        if result == .ok {
            mySelfer?.startMySelf()
        } else {
            MessageModel.performAndWait {
                account.delete()
            }
        }

        accountVerificationResultDelegate?.didVerify(result: result)
    }
}

// MARK: - OAuth2AuthorizationDelegateProtocol

extension LoginViewModel: OAuth2AuthorizationDelegateProtocol {
    func authorizationRequestFinished(error: Error?, accessToken: OAuth2AccessTokenProtocol?) {
        if let err = error {
            loginViewModelOAuth2ErrorDelegate?.handle(oauth2Error: err)
        } else {
            if let token = accessToken {
                Log.shared.info(component: #function, content: "received token \(token)")
                guard let oauth2Params = lastOAuth2Parameters else {
                    loginViewModelOAuth2ErrorDelegate?.handle(
                        oauth2Error: OAuth2InternalError.noParametersForVerification)
                    return
                }
                login(accountName: oauth2Params.emailAddress, userName: oauth2Params.userName,
                      accessToken: accessToken, mySelfer: oauth2Params.mySelfer)
            } else {
                loginViewModelOAuth2ErrorDelegate?.handle(oauth2Error: OAuth2InternalError.noToken)
            }
        }
        lastOAuth2Parameters = nil
        currentOauth2Authorizer = nil
    }
}
