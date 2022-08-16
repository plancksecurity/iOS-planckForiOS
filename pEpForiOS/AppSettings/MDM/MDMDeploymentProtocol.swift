//
//  MDMDeploymentProtocol.swift
//  pEp
//
//  Created by Dirk Zimmermann on 19.05.22.
//  Copyright © 2022 p≡p Security S.A. All rights reserved.
//

import Foundation

/// All error cases thrown by `MDMDeploymentProtocol.deployAccounts`.
enum MDMDeploymentError: Error {
    /// Account settings were found, but the format could not be read/parsed.
    case malformedAccountData

    /// A network error occurred when trying to verify the account
    case networkError
}

protocol MDMDeploymentProtocol {
    /// An MDM account (if any) that can be deployed.
    ///
    /// - Returns: A complete account, ready to be deployed once a password
    /// is supplied, or nil, if no account exists that can be deployed.
    /// - Throws:`MDMDeploymentError`
    func accountToDeploy() throws -> MDMDeployment.AccountData?

    /// Finds out about pre-deployed accounts (via settings that can be pre-deployed via MDM),
    /// and if there are any configured, erases any accounts already set up in the local DB
    /// and sets up the MDM configured accounts,
    /// wiping the MDM configuration settings that triggered the set up after that.
    ///
    /// Calls the given callback when finished, indicating an error (`MDMDeploymentError`, if any),
    /// or complete success.
    ///
    /// - Note: It is an error to call `predeployAccounts` with `haveAccountsToPredeploy`
    /// being `false`, with undefined behavior.
    ///
    /// The format of the required settings is described here: https://confluence.pep.security/x/HgGc
    /// (see "Settings meaning and structure")
    func deployAccounts(callback: @escaping (_ error: MDMDeploymentError?) -> ())

    /// Returns `true` if there is an account to be deployed, `false` otherwise.
    var haveAccountToDeploy: Bool { get }
}
