//
//  MDMAccountDeploymentViewModel.swift
//  pEp
//
//  Created by Dirk Zimmermann on 30.05.22.
//  Copyright © 2022 p≡p Security S.A. All rights reserved.
//

import Foundation

import pEpIOSToolbox

class MDMAccountDeploymentViewModel {
    enum Result: Equatable {
        /// An error ocurred during the pre-deployment
        case error(message: String)

        /// The pre-deployment succeeded
        case success(message: String)
    }

    /// Checks for accounts to deploy, and acts on them.
    func deployAccount(deployer: MDMDeploymentProtocol = MDMDeployment(),
                       callback: @escaping (_ result: Result) -> ()) {
        // TODO: Use a password from the user
        deployer.deployAccount(password: "") { maybeError in
            if let error = maybeError {
                var message: String
                switch error {
                case .localAccountsFound:
                    message = NSLocalizedString("MDM Error: Account(s) already set up",
                                                comment: "MDM deployment error")
                case .alreadyDeployed:
                    message = NSLocalizedString("MDM Error: Already deployed",
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
}
