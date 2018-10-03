//
//  SetOwnKeyViewModel.swift
//  pEp
//
//  Created by Dirk Zimmermann on 03.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

class SetOwnKeyViewModel {
    public var userName: String?
    public var fingerprint: String?
    public var rawErrorString: String?

    func setOwnKey() {
        guard
            let theUserName = userName,
            let theFingerprint = fingerprint,
            !theUserName.isEmpty,
            !theFingerprint.isEmpty
            else {
                rawErrorString = NSLocalizedString(
                    "Please provide a user name and a fingerprint",
                    comment: "Validation error for set_own_key UI")
                return
        }

        let session = PEPSession()

        do {
            let someIdent = PEPIdentity(
                address: "",
                userID: PEP_OWN_USERID,
                userName: theUserName,
                isOwn: true)
            try session.setOwnKey(someIdent, fingerprint: theFingerprint.despaced())
        } catch {
            rawErrorString = error.localizedDescription
        }
    }
}
