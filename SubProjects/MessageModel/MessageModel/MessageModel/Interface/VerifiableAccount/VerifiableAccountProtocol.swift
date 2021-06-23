//
//  VerifiableAccountProtocol.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 15.04.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation

import PantomimeFramework

/// A type of known error that can be thrown by implementations
/// when input data is incomplete or inconsistent.
public enum VerifiableAccountValidationError: Error {
    case invalidUserData
    case unknown
}

extension VerifiableAccountValidationError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidUserData:
            return NSLocalizedString("Some fields seems not to be valid. Please check all input fields.",
                                     comment: "Error description when failing to validate account fields")
        case .unknown:
            return NSLocalizedString("Something went wrong.",
                                     comment: "Error description when failing for an unknown reason")
        }
    }
}

/// The delegate used for the `VerifiableAccountProtocol`.
public protocol VerifiableAccountDelegate: class {
    /// Gets called once the verification has finished, successfully or not.
    /// The given `result` indicates success or failure.
    func didEndVerification(result: Result<Void, Error>)
}

public typealias Success = Bool

/// Objects that can verify accounts and also generate keys.
/// An account currently consist of user data (like login, password etc.)
/// and one IMAP and one SMTP server.
///
/// 1. Fill-in the data, like email address, server names etc.
/// 2. Set the delegate to a class under your control.
/// 3. Call `verify()`. This will throw if the given data is inconsistent or if fail to generate the key.
/// 4. Your delegate will get called when the verification is finished, indicating
///    either success of failure.
/// 5. On success, call `save()` to persist this account.
///    `save()` will throw in any case `verify()` will throw (inconsistent data or fail to generate keys),
///    or when the verification was not successful.
public protocol VerifiableAccountProtocol {
    // MARK: - VerifiableAccountProtocol (delegate)

    /// The delegate to inform when the process has finished, either successfully or not.
    var verifiableAccountDelegate: VerifiableAccountDelegate? { get set }

    // MARK: - VerifiableAccountProtocol (data)

    var accountType: VerifiableAccount.AccountType { get set }

    /// The email address of the account. Used for logging in to the servers.
    var address: String? { get set }

    /// The actual name of the user, or nick name.
    /// Not to be confused with the login name.
    var userName: String? { get set }

    /// Currently, the only use case for this is `.saslXoauth2`.
    /// In all other cases, this should be nil.
    /// Valid for both IMAP and SMTP servers.
    var authMethod: AuthMethod? { get set }

    /// The password, if needed, to log in.
    /// Valid for both IMAP and SMTP servers.
    var password: String? { get set }

    /// Enable/disale keySync to this account only. By default its true.
    /// Only works if keySync is globally enable. Else will be ignored.
    var keySyncEnable: Bool { get set }

    /// If the user chose OAuth2, this is the token. `password` then must be nil.
    /// If set, `authMethod` must be `.saslXoauth2`
    /// Valid for both IMAP and SMTP servers.
    /// - Note: For accounts that require it, this token must be valid or otherwise
    ///         Verification will fail.
    var accessToken: OAuth2AccessTokenProtocol? { get set }

    /// Client Certificate to use to connect to the Servers. `nil` indicates not to use client
    /// certs for this account.
    var clientCertificate: ClientCertificate? { get set }

    /// An optional login name for the servers, if needed.
    /// Falls back to `loginName`
    var loginNameIMAP: String? { get set }

    /// The address of the IMAP server, like 'imap.example.com'.
    var serverIMAP: String? { get set }

    /// The port the IMAP server listens on for new connections.
    var portIMAP: UInt16 { get set }

    /// The transport to be used for IMAP, like TLS.
    var transportIMAP: ConnectionTransport { get set }

    /// An optional login name for the servers, if needed.
    /// Falls back to `loginName`.
    var loginNameSMTP: String? { get set }

    /// The address of the SMTP server, like 'smtp.example.com'.
    var serverSMTP: String? { get set }

    /// The port the SMTP server listens on for new connections.
    var portSMTP: UInt16 { get set }

    /// The transport to be used for SMTP, like TLS.
    var transportSMTP: ConnectionTransport { get set }

    /// Indicates that the IMAP server is to be automaticallyTrusted.
    var isAutomaticallyTrustedImapServer: Bool { get set }

    /// Indicates that the IMAP server is to be manuallyTrusted.
    var isManuallyTrustedImapServer: Bool { get set }

    // MARK: - VerifiableAccountProtocol (behaviour)

    /// Starts login attempts in the background to the indicated servers,
    /// informing the delegate (`verifiableAccountDelegate`) when finished.
    /// - Note: Throws for missing data.
    /// - Throws: VerifiableAccountValidationError
    func verify() throws

    /// When called after a successful `verify()`, prepares the account
    /// (generating keys, fetching folders ...) and saves it.
    /// On success calls `completion` with `success`, otherwise calls it with `failure`.
    /// - Parameter completion: The completion block to be executed after saving.
    func save(completion: @escaping (Result<Void, Error>) -> ())

    // MARK: - VerifiableAccountProtocol (UI support)

    /// The UI might want to know this, i.e. to decide which element is first responder.
    var loginNameIsValid: Bool { get }

    /// The UI might want to know this, i.e. to decide which element is first responder.
    /// - Note: At least one implementation, `VerifiableAccount`, does not take the email into
    /// account at all for this.
    var isValidUser: Bool { get }

    /// Is the server information sufficient to connect the servers?
    /// If false, a query is needed to find them out.
    /// - Note: Doesn't relate to credentials.
    var containsCompleteServerInfo: Bool { get }
}
