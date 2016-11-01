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
        return EmailConnectInfo(
            userId: self.connectInfo.userId, userName: self.connectInfo.userName,
            networkAddress: self.connectInfo.networkAddress,
            networkPort: self.connectInfo.networkPort,
            networkAddressType: nil,
            networkTransportType: nil, emailProtocol: self.connectInfo.emailProtocol!,
            connectionTransport: self.connectInfo.connectionTransport,
            userPassword: password, authMethod: self.connectInfo.authMethod)
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
        if let iServerType = server.serverType?.intValue,
            let serverType = Server.ServerType.init(rawValue: iServerType)?.asString(),
            let key = credentials.key {
            return (server, credentials, KeyChain.password(key: key, serverType: serverType))
        }
        return nil
    }

    open var emailConnectInfos: [EmailConnectInfo] {
        var result = [EmailConnectInfo]()

        guard let creds = credentials else {
            return result
        }
        for cred in creds {
            if let theCred = cred as? CdServerCredentials,
                let servers = theCred.servers {
                for theServer in servers {
                    if let server = theServer as? CdServer {
                        if server.serverType?.intValue == Server.ServerType.imap.rawValue ||
                            server.serverType?.intValue == Server.ServerType.smtp.rawValue {
                            let password = theCred.password
                            if let emailConnectInfo = emailConnectInfo(
                                server: server, credentials: theCred, password: password) {
                                result.append(emailConnectInfo)
                            }
                        }
                    }
                }
            }
        }
        return result
    }

    func emailConnectInfo(server: CdServer, credentials: CdServerCredentials,
        password: String?) -> EmailConnectInfo? {
        let connectionTransport = ConnectionTransport.init(fromInt: server.transport?.intValue)

        if let port = server.port?.int16Value,
            let address = server.address,
            let serverTypeInt = server.serverType?.intValue,
            let serverType = Server.ServerType.init(rawValue: serverTypeInt),
            let emailProtocol = EmailProtocol.init(serverType: serverType) {
            return EmailConnectInfo(
                userId: credentials.userName!, userName: credentials.userName,
                networkAddress: address, networkPort: UInt16(port),
                networkAddressType: nil,
                networkTransportType: nil, emailProtocol: emailProtocol,
                connectionTransport: connectionTransport, userPassword: password,
                authMethod: AuthMethod.init(string: server.authMethod))
        }
        return nil
    }
}
