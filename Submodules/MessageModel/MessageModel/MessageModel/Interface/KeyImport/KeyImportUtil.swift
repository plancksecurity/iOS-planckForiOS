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
        private let keyDataString: String

        fileprivate init(address: String, fingerprint: String, keyDataString: String) {
            self.address = address
            self.fingerprint = fingerprint
            self.keyDataString = keyDataString
        }
    }
}

extension KeyImportUtil: KeyImportUtilProtocol {
    public func importKey(url: URL) throws -> KeyData {
        guard let dataString = try? String(contentsOf: url) else {
            throw ImportError.cannotLoadKey
        }

        let session = PEPSession()

        let identities = try session.importKey(dataString)

        guard let firstIdentity = identities.first else {
            throw ImportError.malformedKey
        }

        guard let fingerprint = firstIdentity.fingerPrint else {
            throw ImportError.malformedKey
        }

        return KeyData(address: firstIdentity.address,
                       fingerprint: fingerprint,
                       keyDataString: dataString)
    }

    public func setOwnKey(keyData: KeyData) throws {
        guard let account = Account.by(address: keyData.address) else {
            throw SetOwnKeyError.noMatchingAccount
        }

        do {
            try account.user.setOwnKey(fingerprint: keyData.fingerprint)
        } catch {
            Log.shared.log(error: error)
            throw SetOwnKeyError.cannotSetOwnKey
        }
    }
}
