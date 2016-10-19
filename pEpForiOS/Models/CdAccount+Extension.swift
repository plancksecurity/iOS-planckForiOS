//
//  CdAccount+Extension.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 17/10/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

import MessageModel

extension CdAccount {
    open var connectInfo: ImapSmtpConnectInfo {
        let passImap = KeyChain.getPassword(self.email,
                                            serverType: Server.ServerType.imap.asString())
        let passSmtp = KeyChain.getPassword(self.email,
                                            serverType: Server.ServerType.smtp.asString())
        return ImapSmtpConnectInfo.init(
            nameOfTheUser: nameOfTheUser,
            email: email, imapUsername: imapUsername, smtpUsername: smtpUsername,
            imapPassword: passImap, smtpPassword: passSmtp,
            imapServerName: self.imapServerName,
            imapServerPort: UInt16(self.imapServerPort.intValue),
            imapTransport: self.rawImapTransport,
            smtpServerName: self.smtpServerName,
            smtpServerPort: UInt16(self.smtpServerPort.intValue),
            smtpTransport: self.rawSmtpTransport)
    }

    open var rawImapTransport: ConnectionTransport {
        return ConnectionTransport(rawValue: self.imapTransport.intValue)!
    }

    open var rawSmtpTransport: ConnectionTransport {
        return ConnectionTransport(rawValue: self.smtpTransport.intValue)!
    }
}
