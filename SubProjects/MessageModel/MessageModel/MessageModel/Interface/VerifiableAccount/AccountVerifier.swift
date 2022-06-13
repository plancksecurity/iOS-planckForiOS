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

/// Wrapper around `VerifiableAccount` using a callback instead of a delegate.
public class AccountVerifier {

    // MARK: - Public API

    public typealias AccountVerifierCallback = (_ error: Error?) -> ()

    public func verify(address: String,
                       userName: String,
                       password: String,
                       serverIMAP: String,
                       portIMAP: UInt16,
                       serverSMTP: String,
                       portSMTP: UInt16,
                       verifiedCallback: @escaping AccountVerifierCallback) {
        self.verifiedCallback = verifiedCallback
        let verifier = VerifiableAccount(verifiableAccountDelegate: self,
                                         address: address,
                                         userName: userName,
                                         imapPassword: password,
                                         smtpPassword: password,
                                         serverIMAP: serverIMAP,
                                         portIMAP: portIMAP,
                                         serverSMTP: serverSMTP,
                                         portSMTP: portSMTP)
        self.verifiableAccount = verifier
    }

    // MARK: - Private

    private var verifiedCallback: AccountVerifierCallback?
    private var verifiableAccount: VerifiableAccountProtocol?
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
        verifiedCallback = nil
        verifiableAccount = nil
    }
}
