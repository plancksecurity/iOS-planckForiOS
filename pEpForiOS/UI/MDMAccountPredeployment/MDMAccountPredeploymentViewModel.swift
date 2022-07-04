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
    enum Result {
        /// An error ocurred during the pre-deployment
        case error(errorMessage: String)

        /// The pre-deployment succeeded
        case success(successMessage: String)
    }

    /// Checks for predeployed accounts, and acts on them.
    func predeployAccounts(callback: @escaping (_ predeploymentError: MDMPredeployedError?) -> ()) {
        let predeployer: MDMPredeployedProtocol = MDMPredeployed()
        predeployer.predeployAccounts { maybeError in
            if let error = maybeError {
                var message: String
                switch error {
                case .networkError:
                    message = NSLocalizedString("MDM Error: Could not connect to account",
                                                comment: "MDM predeployment error")
                case .malformedAccountData:
                    message = NSLocalizedString("MDM Error: Wrong Account Data",
                                                comment: "MDM predeployment error")
                }

                callback(error)
            } else {
                callback(nil)
            }
        }
    }
}
