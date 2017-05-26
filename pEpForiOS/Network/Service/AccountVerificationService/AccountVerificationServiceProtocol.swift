//
//  AccountVerificationServiceProtocol.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 24.05.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import MessageModel

enum AccountVerificationError: Error {
    case networkError
    case noConnectData
    case authenticationError
    case uncategorizedError
}

enum AccountVerificationResult {
    case ok
    case error(AccountVerificationError)
}

extension AccountVerificationResult: Equatable {
    public static func ==(lhs: AccountVerificationResult, rhs: AccountVerificationResult) -> Bool {
        switch (lhs, rhs) {
        case (.ok, .ok):
            return true
        case (.error(let e1), .error(let e2)):
            return e1 == e2
        case (.ok, _):
            return false
        case (.error, _):
            return false
        }
    }
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
