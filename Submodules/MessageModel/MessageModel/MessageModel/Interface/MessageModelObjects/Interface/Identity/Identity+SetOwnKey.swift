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
    public func setOwnKey(fingerprint: String,
                          errorCallback: @escaping (Error) -> (),
                          completion: @escaping () -> ()) {
        let pEpId = pEpIdentity()

        // The fingerprint is not needed by the engine's set_own_key.
        pEpId.fingerPrint = nil

        let me = self // TODO: potential memory leak
        PEPSession().setOwnKey(pEpId,
                                    fingerprint: fingerprint.despaced(),
                                    errorCallback: { (error) in
                                        errorCallback(error)
        }) {
            me.session.perform {
                // We got a new key. Try to derypt yet undecryptable messages.
                let cdAccount = CdAccount.searchAccount(withAddress: me.address,
                                                        context: me.session.moc)
                Message.tryRedecryptYetUndecryptableMessages(for: cdAccount)
                completion()
            }
        }
    }
}
