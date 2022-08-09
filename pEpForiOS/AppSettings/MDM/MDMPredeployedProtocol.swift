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
    /// Finds out about pre-deployed accounts (via settings that can be pre-deployed via MDM).
    ///
    /// - Returns: An account with meta-data, ready to be deployed once a password
    /// is supplied, or nil, if nothing to deploy.
    /// - Throws:`MDMPredeployedError`
    func accountToDeploy() throws -> MDMPredeployed.AccountData?

    /// Finds out about pre-deployed accounts (via settings that can be pre-deployed via MDM),
    /// and if there are any configured, erases any accounts already set up in the local DB
    /// and sets up the MDM configured accounts,
    /// wiping the MDM configuration settings that triggered the set up after that.
    ///
    /// Calls the given callback when finished, indicating an error (`MDMPredeployedError`, if any),
    /// or complete success.
    ///
    /// - Note: It is an error to call `predeployAccounts` with `haveAccountsToPredeploy`
    /// being `false`, with undefined behavior.
    ///
    /// The format of the required settings is described here: https://confluence.pep.security/x/HgGc
    /// (see "Settings meaning and structure")
    func predeployAccounts(callback: @escaping (_ error: MDMPredeployedError?) -> ())

    /// Returns `true` if there is an account to be predeployed, `false` otherwise.
    var haveAccountToPredeploy: Bool { get }
}
