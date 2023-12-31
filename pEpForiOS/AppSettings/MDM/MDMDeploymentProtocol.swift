//
//  MDMDeploymentProtocol.swift
//  pEp
//
//  Created by Dirk Zimmermann on 19.05.22.
//  Copyright © 2022 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel

/// All error cases thrown by `MDMDeploymentProtocol.deployAccount`.
enum MDMDeploymentError: Error {
    /// There are already local accounts, will not deploy.
    case localAccountsFound

    /// Account settings were found, but the format could not be read/parsed.
    case malformedAccountData

    /// Could not log into the account, incoming or outgoing server.
    case authenticationError

    /// A network error occurred when trying to verify the account
    case networkError
}

protocol MDMDeploymentProtocol {
    /// The MDM account (if any) that can be deployed.
    ///
    /// The app typically checks for the existence of such an account,
    /// and if it exists, can ask the user for the password and try to deploy it.
    ///
    /// - Returns: A complete account, ready to be deployed once a password
    /// is supplied, or nil, if no account exists that can be deployed, or MDM is not supposed to be used,
    /// or an account exists already.
    /// - Throws:`MDMDeploymentError`
    func accountToDeploy() throws -> MDMDeployment.AccountData?

    /// Deploys the one and only MDM-deployable account,
    ///
    /// Calls the given callback when finished, indicating an optional error (`MDMDeploymentError`),
    /// or success (in that case the error is `nil`).
    ///
    /// - Note: Don't call this in a non-MDM environment.
    ///
    /// The format of the required settings is described here: https://confluence.pep.security/x/HgGc
    /// (see "Settings meaning and structure")
    ///
    /// - Parameters:
    ///   - password: The password (coming from the user) for this account.
    ///   - accountVerifier: The object used to verify the account.
    ///   - callback: Called after account verification has either succeeded or failed.
    func deployAccount(password: String,
                       accountVerifier: AccountVerifierProtocol,
                       callback: @escaping (_ error: MDMDeploymentError?) -> ())

    /// Returns `true` if there is an account to be deployed, `false` otherwise.
    var haveAccountToDeploy: Bool { get }
}
