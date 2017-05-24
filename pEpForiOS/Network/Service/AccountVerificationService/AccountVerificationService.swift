//
//  AccountVerificationService.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 24.05.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import MessageModel

class AccountVerificationService: AccountVerificationServiceProtocol {
    weak var delegate: AccountVerificationServiceDelegate?
    var accountVerificationState = AccountVerificationState.idle

    func verify(account: Account) {
        delegate?.verified(account: account, service: self, result: .error(.notImplemented))
    }
}
