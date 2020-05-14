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

/// Errors that can occur when setting an own key.
public enum KeyImportUtilProtocolSetOwnKeyError: Error {
    /// No matching account could be found
    case noMatchingAccount

    /// The key could not be set as an own key
    case cannotSetOwnKey
}

protocol KeyImportUtilProtocol {
    /// Imports a key from a local file URL.
    /// - Throws:KeyImportUtilProtocolImportError
    /// - Parameter url: The URL to interpret as ASCII-armored key data
    func importKey(url: URL) throws
}
