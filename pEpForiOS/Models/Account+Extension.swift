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
        guard let addressDefaultAccount = AppSettings.defaultAccount
            else {
                return all().first
        }
        return Account.by(address: addressDefaultAccount)
    }
}
