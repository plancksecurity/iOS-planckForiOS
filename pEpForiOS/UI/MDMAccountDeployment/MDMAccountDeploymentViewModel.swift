//
//  MDMAccountDeploymentViewModel.swift
//  pEp
//
//  Created by Dirk Zimmermann on 30.05.22.
//  Copyright © 2022 p≡p Security S.A. All rights reserved.
//

import Foundation

import PlanckToolbox
import MessageModel

class MDMAccountDeploymentViewModel {

    var accountTypeSelectorViewModel = AccountTypeSelectorViewModel()
    private var accountType: VerifiableAccount.AccountType {
        return accountTypeSelectorViewModel.loginUtil.verifiableAccount.accountType
    }

    enum UIState {
        case accountData(AccountData)
        case noAccountConfiguration(String)
    }

    enum Result: Equatable {
        /// An error ocurred during the pre-deployment
        case error(message: String)

        /// The pre-deployment succeeded
        case success(message: String)
    }

    class AccountData {
        var accountName: String
        var email: String

        init(accountName: String, email: String) {
            self.accountName = accountName
            self.email = email
        }
    }

    enum OAuthProvider {
        case microsoft
        case google

        init(provider: String) {
            if provider == "GOOGLE" {
                self = .google
            } else if provider == "MICROSOFT" {
                self = .microsoft
            } else {
                self = .microsoft
            }
        }

        func toString() -> String {
            switch self {
            case .google:
                return "GOOGLE"
            case .microsoft:
                return "MICROSOFT"
            }
        }
    }

    class OAuthAccountData: AccountData {
        let oauthProvider: OAuthProvider
        init(accountName: String, email: String, oauthProvider: OAuthProvider) {
            self.oauthProvider = oauthProvider
            super.init(accountName: accountName, email: email)
        }
    }

    /// Strong reference in order to keep it alive
    private var accountVerifier: AccountVerifier?

    func uiState() -> UIState {
        if let someAccountData = accountData() {
            return .accountData(someAccountData)
        } else {
            return .noAccountConfiguration(errorNoAccountConfiguration())
        }
    }

    /// - Returns: `AccountData` for the UI to display.
    func accountData() -> AccountData? {
        do {
            if let accountData = try MDMDeployment().accountToDeploy() {
                if let oauthProvider = accountData.oauthProvider {
                    let provider = OAuthProvider(provider: oauthProvider)
                    return OAuthAccountData(accountName: accountData.accountName,
                                            email: accountData.email,
                                            oauthProvider: provider)
                }
                return AccountData(accountName: accountData.accountName, email: accountData.email)
            } else {
                return nil
            }
        } catch {
            return nil
        }
    }
    
    /// Checks for accounts to deploy, and acts on them.
    func deployAccount(password: String,
                       deployer: MDMDeploymentProtocol = MDMDeployment(),
                       callback: @escaping (_ result: Result) -> ()) {
        let theAccountVerifier = AccountVerifier()

        // Keep a strong reference
        self.accountVerifier = theAccountVerifier

        deployer.deployAccount(password: password,
                               accountVerifier: theAccountVerifier) { maybeError in
            // No longer needed
            self.accountVerifier = nil

            if let error = maybeError {
                var message: String
                switch error {
                case .localAccountsFound:
                    message = NSLocalizedString("MDM Error: Account(s) already set up",
                                                comment: "MDM deployment error")
                case .authenticationError:
                    message = NSLocalizedString("MDM Error: Could not log into account",
                                                comment: "MDM deployment error")
                case .networkError:
                    message = NSLocalizedString("MDM Error: Could not connect to account",
                                                comment: "MDM deployment error")
                case .malformedAccountData:
                    message = NSLocalizedString("MDM Error: Wrong Account Data",
                                                comment: "MDM deployment error")
                }

                callback(.error(message: message))
            } else {
                let message = NSLocalizedString("Accounts Deployed",
                                                comment: "MDM deployment message, all ok")

                // Configure all systems (again, to also include e.g. account-bound setup).
                MDMSettingsUtil().configure { _ in
                    callback(.success(message: message))
                }
            }
        }
    }

    // MARK: - Localized Strings

    func errorNoAccountConfiguration() -> String {
        return NSLocalizedString("No account configuration found.",
                                 comment: "No MDM configuration found for account setup")
    }

    func passwordTextFieldPlaceholderText() -> String {
        return NSLocalizedString("Password",
                                 comment: "Placeholder for the password for MDM deployment")
    }

    func verifyButtonTitleText() -> String {
        return NSLocalizedString("Verify",
                                 comment: "Title text for MDM deployment button")
    }

    func errorMessage(message: String) -> String {
        return String.localizedStringWithFormat(NSLocalizedString("Error:\n%1$@",
                                                                  comment: "MDM Deployment Error Format"),
                                                message)
    }
}

//MARK: - OAuth

extension MDMAccountDeploymentViewModel {

    public func shouldShowOauth() -> Bool {
        guard let data = accountData() else {
            return false
        }
        return data is OAuthAccountData
    }

    public func handleDidSelect(viewController : UIViewController? = nil) {
        if let data = accountData() as? OAuthAccountData {
            if data.oauthProvider == .google {
                accountTypeSelectorViewModel.handleDidSelect(accountType: .google, viewController: viewController)
            } else if data.oauthProvider == .microsoft {
                accountTypeSelectorViewModel.handleDidSelect(accountType: .microsoft, viewController: viewController)
            }
        }
    }

    public func handle(error: Error) {
        accountTypeSelectorViewModel.loginUtil.handle(error: error)
    }
}
