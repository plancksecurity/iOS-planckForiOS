//
//  KeyImportUtil.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 14.05.20.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import Foundation

import PEPObjCAdapterFramework

class KeyImportUtil {
}

extension KeyImportUtil: KeyImportUtilProtocol {
    func importKey(url: URL) throws -> KeyImportUtilProtocolKeyData {
        guard let dataString = try? String(contentsOf: url) else {
            throw KeyImportUtilProtocolImportError.cannotLoadKey
        }

        let session = PEPSession()

        let identities = try session.importKey(dataString)

        guard let firstIdentity = identities.first else {
            throw KeyImportUtilProtocolImportError.malformedKey
        }

        guard let fingerprint = firstIdentity.fingerPrint else {
            throw KeyImportUtilProtocolImportError.malformedKey
        }

        return KeyImportUtilProtocolKeyData(address: firstIdentity.address,
                                            fingerprint: fingerprint,
                                            keyDataString: dataString)
    }

    func setOwnKey(keyData: KeyImportUtilProtocolKeyData) throws {
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
