//
//  MDMPredeployedProtocol.swift
//  pEp
//
//  Created by Dirk Zimmermann on 19.05.22.
//  Copyright © 2022 p≡p Security S.A. All rights reserved.
//

import Foundation

/// Error cases thrown by `MDMPredeployedProtocol.predeployAccounts`.
enum MDMPredeployedError: Error {
    /// Account settings were found, but the format could not be read.
    case malformedAccountData
}

protocol MDMPredeployedProtocol {
    /// Finds out about pre-deployed accounts, and if there are any configured, erases the local DB
    /// and sets them up, wiping the very configuration settings that triggered the set up after that.
    ///
    /// Will be called by the app delegate _before_ any account related action has been triggered, e.g., sync services.
    ///
    /// - Throws: `MDMPredeployedError`
    ///
    /// - Note: The logins for the accounts are _not_ checked for validity, that is, a wrong password will not lead
    /// to an immediate error.
    func predeployAccounts() throws
}
