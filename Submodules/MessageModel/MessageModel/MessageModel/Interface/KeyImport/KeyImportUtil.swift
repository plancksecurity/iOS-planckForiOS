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

        /// The key could not be set as an own key for other reasons,
        /// e.g. there was an error in the engine
        case cannotSetOwnKey
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
                          completion: @escaping ([KeyData]) -> ()) {
        guard let dataString = try? String(contentsOf: url) else {
            errorCallback(ImportError.cannotLoadKey)
            return
        }

        PEPAsyncSession().importKey(dataString,
                                    errorCallback: { error in
                                        errorCallback(ImportError.malformedKey)
        }) { identities in
            guard !identities.isEmpty else {
                // Importing a key with 0 identities doesn't make sense, signal an error
                errorCallback(ImportError.malformedKey)
                return
            }

            var identityFoundWithEmptyFingerprint = false
            var keyDatas = [KeyData]()

            for identity in identities {
                guard let fingerprint = identity.fingerPrint else {
                    identityFoundWithEmptyFingerprint = true
                    break
                }
                keyDatas.append(KeyData(address: identity.address,
                                        fingerprint: fingerprint,
                                        userName: identity.userName))
            }

            guard !identityFoundWithEmptyFingerprint else {
                // Consider identities without fingerprint an error
                errorCallback(ImportError.malformedKey)
                return
            }

            completion(keyDatas)
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

            account.user.setOwnKey(fingerprint: fingerprint,
                                   errorCallback: { error in
                                    errorCallback(error)
            }) {
                callback()
            }
        }
    }
}
