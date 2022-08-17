//
//  MDMDeploymentProtocol.swift
//  pEp
//
//  Created by Dirk Zimmermann on 19.05.22.
//  Copyright © 2022 p≡p Security S.A. All rights reserved.
//

import Foundation

/// All error cases thrown by `MDMDeploymentProtocol.deployAccount`.
enum MDMDeploymentError: Error {
    /// There are already local accounts, will not deploy.
    case localAccountsFound

    /// MDM account has already been deployed, will not repeat.
    case alreadyDeployed

    /// Account settings were found, but the format could not be read/parsed.
    case malformedAccountData

    /// A network error occurred when trying to verify the account
    case networkError
}

protocol MDMDeploymentProtocol {
    /// The MDM account (if any) that can be deployed.
    ///
    /// - Returns: A complete account, ready to be deployed once a password
    /// is supplied, or nil, if no account exists that can be deployed.
    /// - Throws:`MDMDeploymentError`
    func accountToDeploy() throws -> MDMDeployment.AccountData?

    /// Finds out about the one and only MDM-deployable account,
    /// and if there is one configured, tries to set it up,
    /// setting a flag after that that the local account has been MDM deployed.
    ///
    /// Calls the given callback when finished, indicating an optional error (`MDMDeploymentError`),
    /// or success (the error is `nil`).
    ///
    /// - Note: Some error conditions: Call `deployAccount` with `haveAccountsToPredeploy`
    /// being `false`, with undefined behavior. Call `deployAccount`
    /// after the initial deployment has already been done. Call `deployAccount` while having
    /// account already set up.
    ///
    /// The format of the required settings is described here: https://confluence.pep.security/x/HgGc
    /// (see "Settings meaning and structure")
    func deployAccount(callback: @escaping (_ error: MDMDeploymentError?) -> ())

    /// Returns `true` if there is an account to be deployed, `false` otherwise.
    var haveAccountToDeploy: Bool { get }
}
