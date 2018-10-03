//
//  SetOwnKeyViewModel.swift
//  pEp
//
//  Created by Dirk Zimmermann on 03.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel

class SetOwnKeyViewModel {
    public var userName: String?
    public var email: String?
    public var fingerprint: String?

    public var rawErrorString: String?

    func setOwnKey() {
        guard
            let theFingerprint = fingerprint,
            !theFingerprint.isEmpty
            else {
                rawErrorString = NSLocalizedString(
                    "Please provide a fingerprint",
                    comment: "Validation error for set_own_key UI")
                return
        }

        guard let foundIdentity = Identity.by(fingerprint: theFingerprint) else {
            rawErrorString = NSLocalizedString(
                "Could not find the fingerprint in the DB",
                comment: "Could not find an Identity by the fingerprint for set_own_key UI")
            return
        }

        let session = PEPSession()

        do {
            let someIdent = PEPIdentity(
                address: foundIdentity.address,
                userID: PEP_OWN_USERID,
                userName: foundIdentity.userName,
                isOwn: true)
            try session.setOwnKey(someIdent, fingerprint: theFingerprint.despaced())
        } catch {
            rawErrorString = error.localizedDescription
        }
    }
}
