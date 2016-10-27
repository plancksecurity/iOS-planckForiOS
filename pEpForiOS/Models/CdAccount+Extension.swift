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
    open var connectInfo: EmailConnectInfo {
        let password = KeyChain.password(key: self.email,
                                         serverType: (self.connectInfo.emailProtocol?.rawValue)!)
        
        return EmailConnectInfo.init(
            emailProtocol: self.connectInfo.emailProtocol!,
            userId: self.connectInfo.userId,
            userPassword: password,
            userName: self.connectInfo.userName,
            networkPort: self.connectInfo.networkPort,
            networkAddress: self.connectInfo.networkAddress,
            connectionTransport: self.connectInfo.connectionTransport,
            authMethod: self.connectInfo.authMethod
        )
    }

    open var rawImapTransport: ConnectionTransport {
        return ConnectionTransport(rawValue: self.imapTransport.intValue)!
    }

    open var rawSmtpTransport: ConnectionTransport {
        return ConnectionTransport(rawValue: self.smtpTransport.intValue)!
    }
}

extension MessageModel.CdAccount {
    func serverNTuple(credentials: CdServerCredentials,
                      server: CdServer) -> (CdServer, CdServerCredentials, String?)? {
        let serverType = Server.ServerType.init(fromInt: server.serverType?.intValue)?.asString()
        if let st = serverType, let key = credentials.key {
            return (server, credentials, KeyChain.password(key: key, serverType: st))
        }
        return nil
    }

    open var emailConnectInfos: (imap: EmailConnectInfo?, smtp: EmailConnectInfo?) {
        var potentialImapServer: (CdServer, CdServerCredentials, String?)?
        var potentialSmtpServer: (CdServer, CdServerCredentials, String?)?

        guard let creds = credentials else {
            return (imap: nil, smtp: nil)
        }
        outer: for cred in creds {
            if let theCred = cred as? CdServerCredentials,
                let servers = theCred.servers {
                for theServer in servers {
                    if let server = theServer as? CdServer {
                        if server.serverType?.intValue == Server.ServerType.imap.rawValue {
                            potentialImapServer = serverNTuple(credentials: theCred,
                                                               server: server)
                        } else if server.serverType?.intValue == Server.ServerType.smtp.rawValue {
                            potentialSmtpServer = serverNTuple(credentials: theCred,
                                                               server: server)
                        }
                        if potentialSmtpServer != nil && potentialImapServer != nil {
                            break outer
                        }
                    }
                }
            }
        }

        if let (imapServer, imapCred, imapPassword) = potentialImapServer,
            let (smtpServer, smtpCred, smtpPassword) = potentialSmtpServer {
            return (imap: emailConnectInfo(
                server: imapServer, credentials: imapCred, password: imapPassword),
                    smtp: emailConnectInfo(
                        server: smtpServer, credentials: smtpCred, password: smtpPassword))
        }

        return (imap: nil, smtp: nil)
    }

    func emailConnectInfo(server: CdServer, credentials: CdServerCredentials,
        password: String?) -> EmailConnectInfo? {
        let connectionTransport = ConnectionTransport.init(
            fromInt: server.transport?.intValue)

        if let port = server.port?.int16Value,
            let address = server.address,
            let emailProtocol = EmailProtocol.init(
                serverType: Server.ServerType.init(fromInt: server.serverType?.intValue)),
            let userID = self.user?.userID {
            return EmailConnectInfo.init(
                emailProtocol: emailProtocol,
                userId: userID,
                userPassword: password,
                userName: credentials.userName ?? self.user?.userName,
                networkPort: UInt16(port),
                networkAddress: address,
                connectionTransport: connectionTransport,
                authMethod: AuthMethod.init(string: server.authMethod))
        }
        return nil
    }
}
