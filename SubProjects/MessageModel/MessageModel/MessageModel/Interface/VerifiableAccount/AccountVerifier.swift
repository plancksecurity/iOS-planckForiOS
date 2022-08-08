//
//  AccountVerifier.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 13.06.22.
//  Copyright © 2022 pEp Security S.A. All rights reserved.
//

import Foundation

import pEpIOSToolbox

// TODO: For ConnectionTransport. Eliminate?
import PantomimeFramework

/// Wrapper around `VerifiableAccount` with some additions and changes,
/// suitable for use in an MDM context.
///
/// Differences to `VerifiableAccount`:
///
/// * Simplified interface
/// * Uses a callback instead of a delegate.
/// * Saves the account after successful verification.
public class AccountVerifier {

    // MARK: - Public API

    public typealias AccountVerifierCallback = (_ error: Error?) -> ()

    // MARK: - ServerData

    public struct ServerData {
        let loginName: String
        let hostName: String
        let port: UInt16
        let transport: ConnectionTransport

        public init?(loginName: String,
                     hostName: String,
                     port: Int,
                     transport: ConnectionTransport) {
            // Check the port first, since this can fail.
            self.port = UInt16(port)
            if Int(self.port) != port {
                return nil
            }

            self.loginName = loginName
            self.hostName = hostName
            self.transport = transport
        }
    }

    // Needed as public method, even if empty.
    public init() {
    }

    /// Calls `VerifiableAccount` and reports the result to `verifiedCallback`.
    /// - Parameters:
    ///   - address: The email address to set up.
    ///   - userName: The user name.
    ///   - password: The password to use for logging into both IMAP and SMTP servers.
    ///   - loginName: The login name to use for both IMAP and SMTP.
    ///   - serverIMAP: The name (address) of the IMAP server.
    ///   - portIMAP: The IMAP port.
    ///   - transportStringIMAP: The transport to use for IMAP. Must be one of
    ///   NONE, SSL/TLS, STARTTLS. Any other value, or not providing it, will default to SSL/TLS.
    ///   - serverSMTP: The name (address) of the SMTP server.
    ///   - portSMTP: The SMTP port.
    ///   - transportStringSMTP: The transport to use for SMTP. Must be one of
    ///   NONE, SSL/TLS, STARTTLS. Any other value, or not providing it, will default to SSL/TLS.
    ///   - verifiedCallback: This closure will be called after the account has been verified successfully,
    /// or in case of error. If there was an error, it will be indicated as the `Error` parameter.
    /// In case of success, the `Error` parameter will be nil.
    public func verify(address: String,
                       userName: String,
                       password: String,
                       loginName: String,
                       serverIMAP: String,
                       portIMAP: UInt16,
                       transportStringIMAP: String,
                       serverSMTP: String,
                       portSMTP: UInt16,
                       transportStringSMTP: String,
                       verifiedCallback: @escaping AccountVerifierCallback) {
        // Store for later use by the delegate (ourselves)
        self.verifiedCallback = verifiedCallback

        let transportIMAP = connectionTransport(fromString: transportStringIMAP,
                                                defaultTransport: .TLS)

        let verifier = VerifiableAccount(verifiableAccountDelegate: self,
                                         address: address,
                                         userName: userName,
                                         imapPassword: password,
                                         smtpPassword: password,
                                         loginNameIMAP: loginName,
                                         serverIMAP: serverIMAP,
                                         portIMAP: portIMAP,
                                         transportIMAP: transportIMAP,
                                         loginNameSMTP: loginName,
                                         serverSMTP: serverSMTP,
                                         portSMTP: portSMTP,
                                         usePEPFolderProvider: self)

        // Keep it alive
        self.verifiableAccount = verifier

        do {
            try verifier.verify()
        } catch {
            verifiedCallback(error)

            // Break possible retain cycles
            resetToNil()
        }
    }

    // MARK: - Private

    private var verifiedCallback: AccountVerifierCallback?
    private var verifiableAccount: VerifiableAccountProtocol?

    /// Set retained member vars to nil, in order to break retain cycles.
    ///
    /// Use after a succesful verification, or on error.
    private func resetToNil() {
        verifiedCallback = nil
        verifiableAccount = nil
    }
}

// MARK: - VerifiableAccountDelegate

extension AccountVerifier: VerifiableAccountDelegate {
    public func didEndVerification(result: Result<Void, Error>) {
        guard let cb = verifiedCallback else {
            Log.shared.errorAndCrash(message: "No verifiedCallback")
            return
        }

        guard let verifiable = verifiableAccount else {
            Log.shared.errorAndCrash(message: "No verifiableAccount")
            return
        }

        switch result {
        case .failure(let err):
            cb(err)
            // Break possible retain cycles
            resetToNil()
        case .success():
            verifiable.save { [weak self] (result) in
                guard let theSelf = self else {
                    Log.shared.lostMySelf()
                    return
                }
                switch result {
                case .success:
                    cb(nil)
                case .failure(let error):
                    cb(error)
                }
                // Break possible retain cycles
                theSelf.resetToNil()
            }
        }
    }
}

// MARK: - UsePEPFolderProviderProtocol

extension AccountVerifier: UsePEPFolderProviderProtocol {
    public var usePepFolder: Bool {
        // TODO: This may have to be connected to MDM settings, instead
        // of being hard-coded.
        return true
    }
}

// MARK: - Parse connection transports

extension AccountVerifier {
    // TODO: This must go away.
    private func connectionTransport(fromString: String,
                                     defaultTransport: ConnectionTransport) -> ConnectionTransport {
        switch (fromString) {
        case "NONE":
            return .plain
        case "SSL/TLS":
            return .TLS
        case "STARTTLS":
            return .startTLS
        default:
            return defaultTransport
        }
    }
}
