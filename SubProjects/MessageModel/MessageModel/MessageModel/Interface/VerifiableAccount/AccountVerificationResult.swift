//
//  AccountVerificationServiceProtocol.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 24.05.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

public enum AccountVerificationResult {
    case ok
    case noImapConnectData
    case noSmtpConnectData
    case imapError(ImapSyncOperationError)
    case smtpError(SmtpSendError)
}
