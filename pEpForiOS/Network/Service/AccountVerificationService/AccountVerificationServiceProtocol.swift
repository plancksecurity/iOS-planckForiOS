//
//  AccountVerificationServiceProtocol.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 24.05.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import MessageModel

enum AccountVerificationResult {
    case ok
    case noImapConnectData
    case noSmtpConnectData
    case imapError(ImapSyncError)
    case smtpError(SmtpSendError)
}

extension AccountVerificationResult: Equatable {
    public static func ==(lhs: AccountVerificationResult, rhs: AccountVerificationResult) -> Bool {
        switch (lhs, rhs) {
        case (.ok, .ok):
            return true
        case (.noImapConnectData, .noImapConnectData):
            return true
        case (.noSmtpConnectData, .noSmtpConnectData):
            return true
        case (.imapError(let e1), .imapError(let e2)):
            return e1 == e2
        case (.smtpError(let e1), .smtpError(let e2)):
            return e1 == e2
        case (.ok, _):
            return false
        case (.imapError, _):
            return false
        case (.smtpError, _):
            return false
        case (.noImapConnectData, _):
            return false
        case (.noSmtpConnectData, _):
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
    var delegate: AccountVerificationServiceDelegate? { get set }
    var accountVerificationState: AccountVerificationState { get }

    /*
     - Note: The account (and dependent objects) must have been saved.
     */
    func verify(account: Account)
}
