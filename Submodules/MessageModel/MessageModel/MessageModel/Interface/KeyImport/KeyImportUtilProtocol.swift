//
//  KeyImportUtilProtocol.swift
//  pEp
//
//  Created by Dirk Zimmermann on 14.05.20.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation

public protocol KeyImportUtilProtocol {
    /// Imports a key from a local file URL.
    /// - Note: The caller is responsible to execute this asynchronously, if needed.
    /// - Parameter url: The URL to interpret as ASCII-armored key data
    /// - Throws: KeyImportUtil.ImportError
    func importKey(url: URL) throws -> KeyImportUtil.KeyData//!!!: IOS-2325_!

    /// Sets the given key as own key.
    /// - Parameter address: The address to set this key as own key to
    /// - Parameter fingerprint: The fingerprint to identify the (already imported) key
    /// - Throws: KeyImportUtil.SetOwnKeyError
    func setOwnKey(address: String, fingerprint: String) throws
}
