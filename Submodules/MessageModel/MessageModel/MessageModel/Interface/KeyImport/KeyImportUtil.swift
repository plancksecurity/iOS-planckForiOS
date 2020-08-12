//
//  KeyImportUtil.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 14.05.20.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import Foundation

import PEPObjCAdapterFramework

public class KeyImportUtil {
    public init() {}
}

extension KeyImportUtil {
    /// Errors that can occur when importing a key.
    public enum ImportError: Error {
        /// The key could not even be loaded
        case cannotLoadKey

        /// The key could be loadad, but not processed
        case malformedKey
    }
}

extension KeyImportUtil {
    /// Errors that can occur when setting an (already imported) key as own key.
    public enum SetOwnKeyError: Error {
        /// No matching account could be found
        case noMatchingAccount
    }
}

extension KeyImportUtil {
    public struct KeyData {
        public let address: String
        public let fingerprint: String

        /// This is not needed for setting an key as own, but may be displayed to the user
        public let userName: String?

        init(address: String, fingerprint: String, userName: String?) {
            self.address = address
            self.fingerprint = fingerprint
            self.userName = userName
        }
    }
}

extension KeyImportUtil: KeyImportUtilProtocol {
    public func importKey(url: URL,
                          errorCallback: @escaping (Error) -> (),
                          completion: @escaping (KeyData) -> ()) {
        guard let dataString = try? String(contentsOf: url) else {
            errorCallback(ImportError.cannotLoadKey)
            return
        }

        PEPAsyncSession().importKey(dataString,
                                    errorCallback: { error in
                                        errorCallback(ImportError.malformedKey)
        }) { identities in
            guard let firstIdentity = identities.first else {
                errorCallback(ImportError.malformedKey)
                return
            }

            guard let fingerprint = firstIdentity.fingerPrint else {
                errorCallback(ImportError.malformedKey)
                return
            }

            completion(KeyData(address: firstIdentity.address,
                               fingerprint: fingerprint,
                               userName: firstIdentity.userName))
        }
    }

    public func setOwnKey(address: String,
                          fingerprint: String,
                          errorCallback: @escaping (Error) -> (),
                          callback: @escaping () -> ()) {
        let session = Session()

        session.performAndWait {
            guard let account = Account.by(address: address, in: session) else {
                errorCallback(SetOwnKeyError.noMatchingAccount)
                return
            }

            KeyImportUtil.setOwnKey(identity: account.user,
                                    fingerprint: fingerprint,
                                    errorCallback: { error in
                                        errorCallback(error)
            }) {
                callback()
            }
        }
    }
}

extension KeyImportUtil {
    /// Set the key with the given fingerprint as the new own key for the given identity.
    /// - Note: The identity to call this on MUST be an own identity!
    /// - Parameter identity: The identity to set own key to.
    /// - Parameter fingerprint: The fingerprint of an already imported key
    /// that should be set as the new own key for this identity.
    /// - Throws: Status code errors from the engine's `set_own_key`.
    static public func setOwnKey(identity: Identity,
                                 fingerprint: String,
                                 errorCallback: @escaping (Error) -> (),
                                 completion: @escaping () -> ()) {
        let pEpId = identity.pEpIdentity()

        // The fingerprint is not needed by the engine's set_own_key.
        pEpId.fingerPrint = nil

        PEPAsyncSession().setOwnKey(pEpId,
                                    fingerprint: fingerprint.despaced(),
                                    errorCallback: { (error) in
                                        errorCallback(error)
        }) {
            identity.session.perform {
                // We got a new key. Try to derypt yet undecryptable messages.
                let cdAccount = CdAccount.searchAccount(withAddress: identity.address,
                                                        context: identity.session.moc)
                Message.tryRedecryptYetUndecryptableMessages(for: cdAccount)
                completion()
            }
        }
    }
}
