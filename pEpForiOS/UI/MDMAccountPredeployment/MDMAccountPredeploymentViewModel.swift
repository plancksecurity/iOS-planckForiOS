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
    /// Checks for predeployed accounts, and acts on them.
    ///
    /// - Note: Silently fails if there was an error is the account description.
    func predeployAccounts(callback: @escaping (_ predeploymentError: MDMPredeployedError?) -> ()) {
        let predeployer: MDMPredeployedProtocol = MDMPredeployed()
        predeployer.predeployAccounts { maybeError in
            if let error = maybeError {
                callback(error)
            } else if let error = maybeError {
                // This should not happen
                Log.shared.errorAndCrash(error: error)
            } else {
                callback(nil)
            }
        }
    }
}
