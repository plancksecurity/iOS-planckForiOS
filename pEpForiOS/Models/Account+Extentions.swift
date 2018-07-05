//
//  Account+Extentions.swift
//  pEp
//
//  Created by Andreas Buff on 07.05.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel

extension Account {
    /// Returns the account that should be used as deafult when sending a message.
    ///
    /// - Returns: default account
    static public func defaultAccount() -> Account? {
        guard let addressDefaultAccount = AppSettings().defaultAccount else {
            return all().first
        }
        return Account.by(address: addressDefaultAccount)
    }

    private func emailConnectInfos() -> [(EmailConnectInfo, ServerCredentials)] {
        var result = [(emailConnectInfo: EmailConnectInfo,
                       serverCredentials: ServerCredentials)]()
        guard let servers = servers else {
            return result
        }

        for server in servers {
            if server.serverType == Server.ServerType.imap
                || server.serverType == Server.ServerType.smtp  {
                let credentials = server.credentials
                if let emailConnectInfo = emailConnectInfo( account: self,
                                                            server: server,
                                                            credentials: server.credentials) {
                    result.append((emailConnectInfo, credentials))
                }
            }
        }

        return result
    }

    func emailConnectInfo(account: Account,
                          server: Server,
                          credentials: ServerCredentials) -> EmailConnectInfo? {
        var result: EmailConnectInfo? = nil
        MessageModel.performAndWait {
            guard
                let cdAccount = CdAccount.search(account: self),
                let cdServer = cdAccount.server(type: server.serverType),
                let cdCredentials = cdServer.credentials,
                let transport = server.transport?.rawValue else {
                    Log.shared.errorAndCrash(component: #function, errorString: "Invalid state")
                    return
            }
            let emailProtocol = EmailProtocol(serverType: server.serverType)
            result =  EmailConnectInfo(accountObjectID: cdAccount.objectID,
                                       serverObjectID: cdServer.objectID,
                                       credentialsObjectID: cdCredentials.objectID,
                                       loginName: credentials.loginName,
                                       loginPasswordKeyChainKey: credentials.key,
                                       networkAddress: server.address,
                                       networkPort: server.port,
                                       networkAddressType: nil,
                                       networkTransportType: nil,
                                       emailProtocol: emailProtocol,
                                       connectionTransport:
                ConnectionTransport(fromInt: Int(transport)),
                                       authMethod: AuthMethod(string: server.authMethod),
                                       trusted: server.trusted)
        }
        return result
    }

     /// - Returns: The first found IMAP connect info.
    var imapConnectInfo: EmailConnectInfo? {
        return emailConnectInfos().filter { return $0.0.emailProtocol == .imap }.first?.0
    }

    /// - Returns: The first found SMTP connect info.
    var smtpConnectInfo: EmailConnectInfo? {
        return emailConnectInfos().filter { return $0.0.emailProtocol == .smtp }.first?.0
    }
}
