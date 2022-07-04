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
    enum State {
        /// Before doing anything
        case initial

        /// In the middle of running
        case checking

        /// An error ocurred during the pre-deployment
        case error

        /// The pre-deployment succeeded
        case success
    }

    /// Checks for predeployed accounts, and acts on them.
    func predeployAccounts(callback: @escaping (_ predeploymentError: MDMPredeployedError?) -> ()) {
        let predeployer: MDMPredeployedProtocol = MDMPredeployed()
        predeployer.predeployAccounts { maybeError in
            if let error = maybeError {
                callback(error)
            } else {
                callback(nil)
            }
        }
    }
}
