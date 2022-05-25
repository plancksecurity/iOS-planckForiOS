//
//  AppDelegate+PredeployedAccounts.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 24.05.22.
//  Copyright © 2022 p≡p Security S.A. All rights reserved.
//

import Foundation

import pEpIOSToolbox

extension AppDelegate {
    /// Checks for predeployed accounts, and acts on them.
    ///
    /// - Note: Silently fails if there was an error is the account description.
    public func predeployAccounts() {
        let predeployer: MDMPredeployedProtocol = MDMPredeployed()
        do {
            try predeployer.predeployAccounts()
        } catch {
            Log.shared.logError(message: "Error during MDM account predeployment: \(error)")
        }
    }
}
