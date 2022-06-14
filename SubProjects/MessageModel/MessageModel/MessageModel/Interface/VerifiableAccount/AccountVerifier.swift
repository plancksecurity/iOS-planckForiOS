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

/// Wrapper around `VerifiableAccount` with a simplified interface, and using a callback instead of a delegate.
public class AccountVerifier {

    // MARK: - Public API

    public typealias AccountVerifierCallback = (_ error: Error?) -> ()

    // Needed as public method, even if empty.
    public init() {
    }

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
    func resetToNil() {
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

        switch result {
        case .failure(let err):
            cb(err)
        case .success():
            cb(nil)
        }

        // Break possible retain cycles
        resetToNil()
    }
}

extension AccountVerifier: UsePEPFolderProviderProtocol {
    public var usePepFolder: Bool {
        return true
    }
}
