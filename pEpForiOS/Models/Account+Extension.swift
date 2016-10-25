//
//  Account+Extension.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 19/10/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

import MessageModel

extension Account {
    open var connectInfo: EmailConnectInfo? {
        var potentialImapServer: Server?
        var potentialSmtpServer: Server?
        for server in servers {
            if server.serverType == .imap {
                potentialImapServer = server
            } else if server.serverType == .smtp {
                potentialSmtpServer = server
            }
        }

        guard let imapServer = potentialImapServer else {
            return nil
        }
        guard let smtpServer = potentialSmtpServer else {
            return nil
        }
        guard let userName = user.userName else {
            return nil
        }

        let passImap = KeyChain.getPassword(user.address,
                                            serverType: Server.ServerType.imap.asString())
        let passSmtp = KeyChain.getPassword(user.address,
                                            serverType: Server.ServerType.smtp.asString())

        return EmailConnectInfo.init() // Caution: No specific values are initialized.
        /* DEPRECATED
        return EmailConnectInfo.init(
            nameOfTheUser: userName,
            email: user.address, imapUsername: imapServer.userName,
            smtpUsername: smtpServer.userName,
            imapPassword: passImap, smtpPassword: passSmtp,
            imapServerName: imapServer.address,
            imapServerPort: UInt16(imapServer.port),
            imapTransport: imapServer.transport?.connectionTransport ?? .TLS,
            smtpServerName: smtpServer.address,
            smtpServerPort: UInt16(smtpServer.port),
            smtpTransport: smtpServer.transport?.connectionTransport ?? .startTLS)
         */
    }
}
