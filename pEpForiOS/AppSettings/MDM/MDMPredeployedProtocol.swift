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
    /// Finds out about pre-deployed accounts, and if there are any configured, erases the local DB
    /// and sets them up, wiping the very configuration settings that triggered the set up after that.
    ///
    /// Calls the given callback when finished, indicating an error (`MDMPredeployedError`, if any),
    /// or complete success.
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
    func predeployAccounts(callback: @escaping (_ error: MDMPredeployedError?) -> ())
}
