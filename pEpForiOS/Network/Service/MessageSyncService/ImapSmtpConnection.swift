//
//  ImapSmtpConnection.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 29.06.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

/**
 Encapsulates an IMAP/SMTP connection, can be used as a key in dictionaries.
 */
struct ImapSmtpConnection: Hashable {
    let imapConnectInfo: EmailConnectInfo
    let smtpConnectInfo: EmailConnectInfo

    var hashValue: Int {
        return imapConnectInfo.hashValue &+ smtpConnectInfo.hashValue
    }
}

extension ImapSmtpConnection: Equatable {
    static func ==(lhs: ImapSmtpConnection, rhs: ImapSmtpConnection) -> Bool {
        return lhs.imapConnectInfo == rhs.imapConnectInfo &&
            lhs.smtpConnectInfo == rhs.smtpConnectInfo
    }
}
