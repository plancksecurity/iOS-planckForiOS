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
    func serverTuple(credentials: ServerCredentials, server: Server) -> (Server, String?)? {
        return (server, KeyChain.getPassword(
            credentials.key, serverType: server.serverType.asString()))
    }

    open var connectInfo: EmailConnectInfo? {
        var potentialImapServer: (Server, String?)?
        var potentialSmtpServer: (Server, String?)?

        outer: for cred in serverCredentials {
            for server in cred.servers {
                if server.serverType == .imap {
                    potentialImapServer = serverTuple(credentials: cred, server: server)
                } else if server.serverType == .smtp {
                    potentialSmtpServer = serverTuple(credentials: cred, server: server)
                }
                if potentialSmtpServer != nil && potentialImapServer != nil {
                    break outer
                }
            }
        }

        guard let (imapServer, passImap) = potentialImapServer else {
            return nil
        }
        guard let (smtpServer, passSmtp) = potentialSmtpServer else {
            return nil
        }
        guard let userName = user.userName else {
            return nil
        }

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
