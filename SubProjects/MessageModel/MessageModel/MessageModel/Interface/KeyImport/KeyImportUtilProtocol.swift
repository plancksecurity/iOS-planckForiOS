//
//  KeyImportUtilProtocol.swift
//  pEp
//
//  Created by Dirk Zimmermann on 14.05.20.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation

public protocol KeyImportUtilProtocol {
    /// Asynchronously imports a key from a local file URL and calls back.
    /// - Parameter url: The URL to interpret as ASCII-armored key data
    /// - Parameter errorCallback: The error handler (called async)
    /// - Parameter completion: The completions block called on success
    /// - Throws: KeyImportUtil.ImportError
    func importKey(url: URL,
                   errorCallback: @escaping (Error) -> (),
                   completion: @escaping ([KeyImportUtil.KeyData]) -> ())

    /// Asynchronously sets the given key as own key.
    /// - Parameter userName: The user name to set this key as own key to
    /// - Parameter address: The address to set this key as own key to
    /// - Parameter fingerprint: The fingerprint to identify the (already imported) key
    /// - Parameter errorCallback: Callback for signaling that an error ocurred.
    /// - Parameter callback: Callback for signaling success.
    /// - Throws: Since the function works async, no error gets thrown, but instead
    /// given as parameter to the `errorCallback`: KeyImportUtil.SetOwnKeyError,
    /// SetOwnKeyError.noMatchingAccount
    func setOwnKey(userName: String,
                   address: String,
                   fingerprint: String,
                   errorCallback: @escaping (Error) -> (),
                   callback: @escaping () -> ())
}
