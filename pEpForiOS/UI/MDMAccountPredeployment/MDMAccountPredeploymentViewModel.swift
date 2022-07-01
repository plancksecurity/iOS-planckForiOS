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
