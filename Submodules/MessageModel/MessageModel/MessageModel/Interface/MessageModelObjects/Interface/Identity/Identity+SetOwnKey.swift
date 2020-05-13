//
//  Identity+SetOwnKey.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 13.05.20.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import Foundation

import PEPObjCAdapterFramework

extension Identity {
    /// Set the key with the given fingerprint as the now key for the identity.
    /// - Parameter fingerprint: The fingerprint of an already imported key
    /// that should be the new key for this identity.
    /// - Throws: Status code errors from the engine's `set_own_key`.
    public func setOwnKey(fingerprint: String) throws {
        let pEpId = pEpIdentity()

        // The fingerprint is not needed by the engine's set_own_key.
        pEpId.fingerPrint = nil

        let session = PEPSession()
        try session.setOwnKey(pEpId, fingerprint: fingerprint)
    }
}
