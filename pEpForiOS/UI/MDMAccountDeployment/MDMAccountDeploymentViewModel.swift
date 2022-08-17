//
//  MDMAccountPredeploymentViewModel.swift
//  pEp
//
//  Created by Dirk Zimmermann on 30.05.22.
//  Copyright © 2022 p≡p Security S.A. All rights reserved.
//

import Foundation

import pEpIOSToolbox

class MDMAccountPredeploymentViewModel {
    enum Result: Equatable {
        /// An error ocurred during the pre-deployment
        case error(message: String)

        /// The pre-deployment succeeded
        case success(message: String)
    }

    /// Checks for predeployed accounts, and acts on them.
    func deployAccount(predeployer: MDMDeploymentProtocol = MDMDeployment(),
                       callback: @escaping (_ result: Result) -> ()) {
        predeployer.deployAccount { maybeError in
            if let error = maybeError {
                var message: String
                switch error {
                case .alreadyDeployed:
                    message = NSLocalizedString("MDM Error: Already deployed",
                                                comment: "MDM predeployment error")
                case .networkError:
                    message = NSLocalizedString("MDM Error: Could not connect to account",
                                                comment: "MDM predeployment error")
                case .malformedAccountData:
                    message = NSLocalizedString("MDM Error: Wrong Account Data",
                                                comment: "MDM predeployment error")
                }

                callback(.error(message: message))
            } else {
                let message = NSLocalizedString("Accounts Deployed",
                                                comment: "MDM predeployment message, all ok")

                callback(.success(message: message))
            }
        }
    }
}
