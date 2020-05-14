//
//  KeyImportUtilProtocol.swift
//  pEp
//
//  Created by Dirk Zimmermann on 14.05.20.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation

/// Errors that can occur when importing a key.
public enum KeyImportUtilProtocolImportError: Error {
    /// The key could not even be loaded
    case cannotLoadKey

    /// The key could be loadad, but not processed
    case malformedKey
}

/// Errors that can occur when setting an (already imported) key as own key.
public enum KeyImportUtilProtocolSetOwnKeyError: Error {
    /// No matching account could be found
    case noMatchingAccount

    /// The key could not be set as an own key for other reasons,
    /// e.g. there was an error in the engine
    case cannotSetOwnKey
}

public struct KeyImportUtilProtocolKeyData {
    let address: String
    let fingerprint: String
    let keyDataString: String
}

public protocol KeyImportUtilProtocol {
    /// Imports a key from a local file URL.
    /// - Note: The caller is responsible to execute this asynchronously, if needed.
    /// - Parameter url: The URL to interpret as ASCII-armored key data
    /// - Throws: KeyImportUtilProtocolImportError
    func importKey(url: URL) throws -> KeyImportUtilProtocolKeyData

    /// Sets the given key as own key.
    /// - Parameter keyData: The key data for the key to be set as own key
    /// - Throws: KeyImportUtilProtocolSetOwnKeyError
    func setOwnKey(keyData: KeyImportUtilProtocolKeyData) throws
}
