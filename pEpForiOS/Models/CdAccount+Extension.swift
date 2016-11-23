//
//  CdAccount+Extension.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 17/10/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import MessageModel

extension CdAccount {
    /**
     This is a blatant lie, and must be removed!
     */
    open var connectInfo: EmailConnectInfo {
        let password = KeyChain.password(key: "key",
                                         serverType: (self.connectInfo.emailProtocol?.rawValue)!)
        return EmailConnectInfo(
            accountObjectID: objectID,
            serverObjectID: objectID,
            loginName: self.connectInfo.loginName!,
            loginPassword: password,
            networkAddress: self.connectInfo.networkAddress,
            networkPort: self.connectInfo.networkPort,
            networkAddressType: nil,
            networkTransportType: nil, emailProtocol: self.connectInfo.emailProtocol!,
            connectionTransport: self.connectInfo.connectionTransport,
            authMethod: self.connectInfo.authMethod)
    }

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

    open var imapConnectInfo: EmailConnectInfo? {
        let cis = emailConnectInfos
        for k in cis.keys {
            if k.emailProtocol == .imap {
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
            let serverType = Server.ServerType.init(rawValue: serverTypeInt),
            let emailProtocol = EmailProtocol.init(serverType: serverType) {
            return EmailConnectInfo(
                accountObjectID: account.objectID, serverObjectID: server.objectID,
                loginName: credentials.userName,
                loginPassword: password,
                networkAddress: address, networkPort: UInt16(port),
                networkAddressType: nil,
                networkTransportType: nil, emailProtocol: emailProtocol,
                connectionTransport: connectionTransport,
                authMethod: AuthMethod.init(string: server.authMethod))
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
