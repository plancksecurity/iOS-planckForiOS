//
//  AccountVerifier.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 13.06.22.
//  Copyright © 2022 pEp Security S.A. All rights reserved.
//

import Foundation

import PantomimeFramework
import pEpIOSToolbox

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
    ///   - serverSMTP: The name (address) of the SMTP server.
    ///   - portSMTP: The SMTP port.
    ///   - verifiedCallback: This closure will be called after the account has been verified successfully,
    /// or in case of error. If there was an error, it will be indicated as the `Error` parameter.
    /// In case of success, the `Error` parameter will be nil.
    public func verify(address: String,
                       userName: String,
                       password: String,
                       loginName: String,
                       serverIMAP: String,
                       portIMAP: UInt16,
                       serverSMTP: String,
                       portSMTP: UInt16,
                       verifiedCallback: @escaping AccountVerifierCallback) {
        // Store for later use by the delegate (ourselves)
        self.verifiedCallback = verifiedCallback

        let verifier = VerifiableAccount(verifiableAccountDelegate: self,
                                         address: address,
                                         userName: userName,
                                         imapPassword: password,
                                         smtpPassword: password,
                                         loginNameIMAP: loginName,
                                         serverIMAP: serverIMAP,
                                         portIMAP: portIMAP,
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
            defer {
                // Break possible retain cycles
                resetToNil()
            }
            cb(err)
        case .success():
            verifiable.save { [weak self] (result) in
                guard let theSelf = self else {
                    Log.shared.lostMySelf()
                    return
                }

                defer {
                    // Break possible retain cycles
                    theSelf.resetToNil()
                }

                switch result {
                case .success:
                    cb(nil)
                case .failure(let error):
                    cb(error)
                }
            }
        }
    }
}

extension AccountVerifier: UsePEPFolderProviderProtocol {
    public var usePepFolder: Bool {
        // TODO: This may have to be connected to MDM settings, instead
        // of being hard-coded.
        return true
    }
}
