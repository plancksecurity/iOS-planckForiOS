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

    init(address: String? = nil,
         userName: String? = nil,
         authMethod: AuthMethod? = nil,
         imapPassword: String? = nil,
         smtpPassword: String? = nil,
         accessToken: OAuth2AccessTokenProtocol? = nil,
         loginNameIMAP: String? = nil,
         serverIMAP: String? = nil,
         portIMAP: UInt16 = 993,
         transportIMAP: ConnectionTransport = ConnectionTransport.TLS,
         loginNameSMTP: String? = nil,
         serverSMTP: String? = nil,
         portSMTP: UInt16 = 587,
         transportSMTP: ConnectionTransport = ConnectionTransport.startTLS,
         automaticallyTrustedImapServer: Bool = false,
         manuallyTrustedImapServer: Bool = false,
         keySyncEnable: Bool = true,
         containsCompleteServerInfo: Bool = false,
         usePEPFolderProvider: UsePEPFolderProviderProtocol? = nil,
         originalImapPassword: String? = nil,
         originalSmtpPassword: String? = nil) {
    }

    public func verify(verifiedCallback: @escaping AccountVerifierCallback) {
        self.verifiedCallback = verifiedCallback
        // TODO Kick off the verification
    }

    // MARK: - Private

    private var verifiedCallback: AccountVerifierCallback?
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
        self.verifiedCallback = nil
    }
}
