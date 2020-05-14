//
//  KeyImportUtilProtocol.swift
//  pEp
//
//  Created by Dirk Zimmermann on 14.05.20.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation

public struct KeyImportUtilProtocolKeyData {
    let address: String
    let fingerprint: String
    let keyDataString: String
}

public protocol KeyImportUtilProtocol {
    /// Imports a key from a local file URL.
    /// - Note: The caller is responsible to execute this asynchronously, if needed.
    /// - Parameter url: The URL to interpret as ASCII-armored key data
    /// - Throws: ImportError
    func importKey(url: URL) throws -> KeyImportUtilProtocolKeyData

    /// Sets the given key as own key.
    /// - Parameter keyData: The key data for the key to be set as own key
    /// - Throws: SetOwnKeyError
    func setOwnKey(keyData: KeyImportUtilProtocolKeyData) throws
}
