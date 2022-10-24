//
//  MDMAccountDeploymentViewModel.swift
//  pEp
//
//  Created by Dirk Zimmermann on 30.05.22.
//  Copyright © 2022 p≡p Security S.A. All rights reserved.
//

import Foundation

import pEpIOSToolbox
import MessageModel

class MDMAccountDeploymentViewModel {
    enum UIState {
        case initial
    }

    struct AccountData {
        let accountName: String
        let email: String
    }

    enum Result: Equatable {
        /// An error ocurred during the pre-deployment
        case error(message: String)

        /// The pre-deployment succeeded
        case success(message: String)
    }

    private(set) var uiState: UIState = .initial

    /// Strong reference in order to keep it alive
    private var accountVerifier: AccountVerifier?

    /// - Returns: `AccountData` for the UI to display.
    func accountData() -> AccountData? {
        do {
            if let accountData = try MDMDeployment().accountToDeploy() {
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

                callback(.success(message: message))
            }
        }
    }

    // MARK: - Localized Strings

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
