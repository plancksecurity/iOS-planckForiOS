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

    public func setOwnKey(callback: @escaping (String?) -> ()) {
        guard
            let theEmail = email,
            let theFingerprint = fingerprint,
            !theEmail.isEmpty,
            !theFingerprint.isEmpty
            else {
                callback(NSLocalizedString(
                    "Please provide an email and a fingerprint. The email must match an existing account.",
                    comment: "Validation error for set_own_key UI"))
                return
        }

        guard let identity = ownIdentityBy(email: theEmail) else {
            callback(NSLocalizedString(
                "No account found with the given email.",
                comment: "Error when no account found for set_own_key UI"))
            return
        }

        identity.setOwnKey(fingerprint: theFingerprint,
                           errorCallback: { error in callback(error.localizedDescription) },
                           completion: { callback(nil) })
    }
}

// MARK: - Private

extension SetOwnKeyViewModel {

    private func ownIdentityBy(email: String) -> Identity? {
        return Account.by(address: email)?.user
    }
}
