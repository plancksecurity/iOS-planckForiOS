//
//  Account+AccountType.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 29.04.20.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import Foundation

extension Account {
    /// Wraps `CdAccount.accountType`.
    public var accountType: VerifiableAccount.AccountType? {
        return cdObject.accountType
    }
}
