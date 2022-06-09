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

    /// A network error occurred when trying to verify the account
    case networkError
}

protocol MDMPredeployedProtocol {
    /// - Returns: `true` if there are accounts waiting to be predeployed, `false` otherwise.
    func hasPredeployableAccounts() -> Bool

    /// Finds out about pre-deployed accounts, and if there are any configured, erases the local DB
    /// and sets them up, wiping the very configuration settings that triggered the set up after that.
    ///
    /// - Throws: `MDMPredeployedError`
    ///
    /// - Note: The logins for the accounts are _not_ checked for validity, that is, a wrong password will not lead
    /// to an immediate error.
    ///
    /// The format of the required settings is as follows:
    ///
    ///     MDM: Dictionary
    ///              predeployedAcounts: Array of AccountDictionary
    ///
    /// The format of a single account description (`AccountDictionary`):
    ///
    ///     userName: String
    ///     loginName: String
    ///     password: String
    ///     imapServer: Dictionary
    ///       name: String
    ///       port: Integer
    ///     smtpServer: Dictionary
    ///       name: String
    ///       port: Integer
    func predeployAccounts() throws
}
