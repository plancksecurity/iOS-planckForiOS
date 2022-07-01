//
//  MDMPredeployedProtocol.swift
//  pEp
//
//  Created by Dirk Zimmermann on 19.05.22.
//  Copyright © 2022 p≡p Security S.A. All rights reserved.
//

import Foundation

/// All error cases thrown by `MDMPredeployedProtocol.predeployAccounts`.
enum MDMPredeployedError: Error {
    /// Account settings were found, but the format could not be read/parsed.
    case malformedAccountData

    /// A network error occurred when trying to verify the account
    case networkError
}

protocol MDMPredeployedProtocol {
    /// Finds out about pre-deployed accounts (via settings that can be pre-deployed via MDM),
    /// and if there are any configured, erases any accounts already set up in the local DB
    /// and sets up the MDM configured accounts,
    /// wiping the MDM configuration settings that triggered the set up after that.
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

    /// Returns `true` if there are accounts to be predeployed, `false` otherwise.
    var haveAccountsToPredeploy: Bool { get }
}
