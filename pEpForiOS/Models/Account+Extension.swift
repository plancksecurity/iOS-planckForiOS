//
//  Account+Extension.swift
//  pEp
//
//  Created by Dirk Zimmermann on 08.04.19.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel

extension Account {
    /// Returns the account that should be used as deafult when sending a message.
    ///
    /// - Returns: default account
    static public func defaultAccount() -> Account? {
        guard let addressDefaultAccount = AppSettings.shared.defaultAccount
            else {
                return all().first
        }
        return Account.by(address: addressDefaultAccount)
    }
    
    var signature: String {
        get {
            let signatures = AppSettings.shared.signatureAddresDictionary
            return signatures[user.address] ?? String.pepSignature
        }
        set {
            var signatures = AppSettings.shared.signatureAddresDictionary
            signatures[user.address] = newValue
            AppSettings.shared.signatureAddresDictionary = signatures
        }
    }
}
