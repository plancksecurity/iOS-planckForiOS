//
//  Identity+SetOwnKey.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 13.05.20.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import Foundation

import PEPObjCAdapterFramework
import pEpIOSToolbox

extension Identity {
    /// Set the key with the given fingerprint as the new own key for the identity.
    /// - note:The identity to call this on MUST be an own identity!
    /// - Parameter fingerprint: The fingerprint of an already imported key
    /// that should be set as the new own key for this identity.
    /// - Throws: Status code errors from the engine's `set_own_key`.
    public func setOwnKey(fingerprint: String) throws {
        let pEpId = pEpIdentity()

        // The fingerprint is not needed by the engine's set_own_key.
        pEpId.fingerPrint = nil

        let pEpSession = PEPSession()
        try pEpSession.setOwnKey(pEpId, fingerprint: fingerprint.despaced())

        // We got a new key. Try to derypt yet undecryptable messages.
        let cdAccount = CdAccount.searchAccount(withAddress: address, context: session.moc)
        Message.tryRedecryptYetUndecryptableMessages(for: cdAccount)
    }
}
