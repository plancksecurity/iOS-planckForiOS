//
//  SetOwnKeyViewModel.swift
//  pEp
//
//  Created by Dirk Zimmermann on 03.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel
import PEPObjCAdapterFramework

class SetOwnKeyViewModel {
    public var userName: String?
    public var email: String?
    public var fingerprint: String?

    public var rawErrorString: String?

    public func setOwnKey() {
        guard
            let theEmail = email,
            let theFingerprint = fingerprint,
            !theEmail.isEmpty,
            !theFingerprint.isEmpty
            else {
                rawErrorString = NSLocalizedString(
                    "Please provide an email and a fingerprint. The email must match an existing account.",
                    comment: "Validation error for set_own_key UI")
                return
        }

        guard let theIdent = ownIdentityBy(email: theEmail) else {
            rawErrorString = NSLocalizedString(
                "No account found with the given email.",
                comment: "Error when no account found for set_own_key UI")
            return
        }

        let someIdent = theIdent.pEpIdentity()
        someIdent.fingerPrint = nil // just in case

        do {
            let session = PEPSession()
            try session.setOwnKey(someIdent, fingerprint: theFingerprint.despaced())
            rawErrorString = nil
        } catch {
            rawErrorString = error.localizedDescription
        }
    }

    private func ownIdentityBy(email: String) -> Identity? {
        return Account.by(address: email)?.user
    }
}
