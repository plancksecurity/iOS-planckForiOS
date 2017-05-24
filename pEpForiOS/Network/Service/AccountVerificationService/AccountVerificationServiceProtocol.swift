//
//  AccountVerificationServiceProtocol.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 24.05.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit

import MessageModel

enum AccountVerificationError: Error {
    case networkError
    case loginErrorIMAP
    case loginErrorSMTP
}

enum AccountVerificationResult {
    case ok
    case error(AccountVerificationError)
}

enum AccountVerificationState {
    case idle
    case verifying
}

protocol AccountVerificationServiceDelegate: class {
    func verified(account: Account, service: AccountVerificationServiceProtocol,
                  result: AccountVerificationResult)
}

protocol AccountVerificationServiceProtocol {
    weak var delegate: AccountVerificationServiceDelegate? { get set }
    var accountVerificationState: AccountVerificationState { get }

    func verify(account: Account)
}
