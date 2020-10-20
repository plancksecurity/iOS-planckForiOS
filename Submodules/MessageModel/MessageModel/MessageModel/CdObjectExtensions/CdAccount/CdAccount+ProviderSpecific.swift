//
//  CdAccount+ProviderSpecific.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 18.03.20.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import Foundation

import pEpIOSToolbox

extension CdAccount {
    /// The account type that was used when creating this account, if able to
    /// determine from the IMAP and SMTP server.
    ///
    /// Is `nil` for account types without fixed servers, like `.other` or `.clientCertificate`.
    /// - Note: Based on servers, it's impossible to distinguish .outlook and .o365,
    /// the caller must be able to handle that, i.e. receiving .o365 for an outlook.com account.
    var accountType: VerifiableAccount.AccountType? {
        guard let imapServer = server(type: .imap), let smtpServer = server(type: .smtp) else {
            // For now, an account must have both IMAP and SMTP.
            Log.shared.errorAndCrash("Account without IMAP or SMTP server: %@",
                                     identity?.address ?? "unknown")
            return nil
        }

        guard let imapServerAddress = imapServer.address,
            let smtpServerAddress = smtpServer.address else {
            Log.shared.errorAndCrash("IMAP or SMTP server without server adress: %@",
                                     identity?.address ?? "unknown")
            return nil
        }

        for acType in VerifiableAccount.AccountType.allCases {
            let verifiableAccount = VerifiableAccount.verifiableAccount(for: acType)
            if let verifiableImapServerAddress = verifiableAccount.serverIMAP,
                let verifiableSmtpServerAddress = verifiableAccount.serverSMTP {
                if verifiableImapServerAddress == imapServerAddress &&
                    verifiableSmtpServerAddress == smtpServerAddress {
                    return acType
                }
            }
        }

        return nil
    }
}
