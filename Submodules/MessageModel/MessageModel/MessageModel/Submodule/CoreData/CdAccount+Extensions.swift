//
//  CdAccount+Extensions.swift
//  MessageModel
//
//  Created by Xavier Algarra on 08/12/16.
//  Copyright © 2016 pEp Security S.A. All rights reserved.
//

import Foundation

extension CdAccount {
    func serverNTuple(credentials: CdServerCredentials,
                      server: CdServer) -> (CdServer, CdServerCredentials, String?)? {
        if let serverType = Server.ServerType.init(rawValue: Int(server.serverType))?.asString(),
            let key = credentials.key {
            return (server, credentials, KeyChain.password(key: key, serverType: serverType))
        }
        return nil
    }

    open var emailConnectInfos: [EmailConnectInfo: CdServerCredentials] {
        var result = [EmailConnectInfo: CdServerCredentials]()

        guard let creds = credentials else {
            return result
        }
        for cred in creds {
            if let theCred = cred as? CdServerCredentials,
                let servers = theCred.servers {
                for theServer in servers {
                    if let server = theServer as? CdServer {
                        if Int(server.serverType) == Server.ServerType.imap.rawValue ||
                            Int(server.serverType) == Server.ServerType.smtp.rawValue {
                            let password = theCred.password
                            if let emailConnectInfo = emailConnectInfo(
                                account: self, server: server, credentials: theCred,
                                password: password) {
                                result[emailConnectInfo] = theCred
                            }
                        }
                    }
                }
            }
        }
        return result
    }

    /**
     - Returns: The first found IMAP connect info. Used by some tests.
     */
    open var imapConnectInfo: EmailConnectInfo? {
        let cis = emailConnectInfos
        for k in cis.keys {
            if k.emailProtocol == .imap {
                return k
            }
        }
        return nil
    }

    /**
     - Returns: The first found SMTP connect info. Used by some tests.
     */
    open var smtpConnectInfo: EmailConnectInfo? {
        let cis = emailConnectInfos
        for k in cis.keys {
            if k.emailProtocol == .smtp {
                return k
            }
        }
        return nil
    }

    func emailConnectInfo(account: CdAccount, server: CdServer,
                          credentials: CdServerCredentials,
                          password: String?) -> EmailConnectInfo? {
        let connectionTransport = ConnectionTransport(fromInt: Int(server.transport))

        let serverTypeInt = Int(server.serverType)
        if let port = server.port?.int16Value,
            let address = server.address,
            let serverType = Server.ServerType(rawValue: serverTypeInt),
            let emailProtocol = EmailProtocol(serverType: serverType) {
            return EmailConnectInfo(
                accountObjectID: account.objectID, serverObjectID: server.objectID,
                loginName: credentials.userName,
                loginPassword: password,
                networkAddress: address, networkPort: UInt16(port),
                networkAddressType: nil,
                networkTransportType: nil, emailProtocol: emailProtocol,
                connectionTransport: connectionTransport,
                authMethod: AuthMethod(string: server.authMethod),
                trusted: server.trusted)
        }
        return nil
    }

    /**
     - Returns: A folder under this account with the given name.
     */
    open func folder(byName name: String) -> CdFolder? {
        return CdFolder.first(with: ["account": self, "name": name])
    }
    
}
