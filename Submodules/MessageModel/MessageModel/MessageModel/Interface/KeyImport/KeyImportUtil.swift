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

        fileprivate init(address: String, fingerprint: String) {
            self.address = address
            self.fingerprint = fingerprint
        }
    }
}

extension KeyImportUtil: KeyImportUtilProtocol {
    public func importKey(url: URL) throws -> KeyData {
        guard let dataString = try? String(contentsOf: url) else {
            throw ImportError.cannotLoadKey
        }

        let session = PEPSession()

        var identities = [PEPIdentity]()

        do {
            identities = try session.importKey(dataString)
        } catch {
            throw ImportError.malformedKey
        }

        guard let firstIdentity = identities.first else {
            throw ImportError.malformedKey
        }

        guard let fingerprint = firstIdentity.fingerPrint else {
            throw ImportError.malformedKey
        }

        return KeyData(address: firstIdentity.address,
                       fingerprint: fingerprint)
    }

    public func setOwnKey(address: String, fingerprint: String) throws {
        guard let account = Account.by(address: address) else {
            throw SetOwnKeyError.noMatchingAccount
        }

        do {
            try account.user.setOwnKey(fingerprint: fingerprint)
        } catch {
            Log.shared.log(error: error)
            throw SetOwnKeyError.cannotSetOwnKey
        }
    }
}
