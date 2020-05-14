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

extension KeyImportUtil: KeyImportUtilProtocol {
    public func importKey(url: URL) throws -> KeyImportUtilProtocolKeyData {
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

        return KeyImportUtilProtocolKeyData(address: firstIdentity.address,
                                            fingerprint: fingerprint,
                                            keyDataString: dataString)
    }

    public func setOwnKey(keyData: KeyImportUtilProtocolKeyData) throws {
        guard let account = Account.by(address: keyData.address) else {
            throw KeyImportUtilProtocolSetOwnKeyError.noMatchingAccount
        }

        do {
            try account.user.setOwnKey(fingerprint: keyData.fingerprint)
        } catch {
            Log.shared.log(error: error)
            throw KeyImportUtilProtocolSetOwnKeyError.cannotSetOwnKey
        }
    }
}
