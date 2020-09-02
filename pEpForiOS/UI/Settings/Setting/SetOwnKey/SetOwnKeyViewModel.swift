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
    public var email: String?
    public var fingerprint: String?

    private let keyImporter: KeyImportUtilProtocol

    public init(keyImporter: KeyImportUtilProtocol = KeyImportUtil()) {
        self.keyImporter = keyImporter
    }

    /// Tries to set the own key based on member variables and
    /// invokes `callback`.
    /// - Parameter callback: After an attempt of invoking `setOwnKey`, will get called
    /// with an error message in case of error, or nil, if the `setOwnKey` succeeded.
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

        guard let theUserName = identity.userName else {
            callback(NSLocalizedString(
                "The account with the given email has no user name.",
                comment: "Error when account found for set_own_key UI, but has no user name"))
            return
        }

        keyImporter.setOwnKey(userName: theUserName,
                              address: theEmail,
                              fingerprint: theFingerprint,
                              errorCallback: { err in
                                if let setOwnKeyError = err as? KeyImportUtil.SetOwnKeyError {
                                    switch(setOwnKeyError) {
                                    case .noMatchingAccount:
                                        callback(NSLocalizedString(
                                            "No account found with the given email.",
                                            comment: "Error when no account found for set_own_key UI"))
                                    }
                                } else {
                                    callback(err.localizedDescription)
                                }
        }) {
            callback(nil)
        }
    }
}

// MARK: - Private

extension SetOwnKeyViewModel {
    private func ownIdentityBy(email: String) -> Identity? {
        return Account.by(address: email)?.user
    }
}
