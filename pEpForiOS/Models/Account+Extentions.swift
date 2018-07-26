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
        guard let addressDefaultAccount = AppSettings.defaultAccount else {
            return all().first
        }
        return Account.by(address: addressDefaultAccount)
    }

    func emailConnectInfos() -> [EmailConnectInfo] {
        var result = [EmailConnectInfo]()
        guard let servers = servers else {
            return result
        }

        for server in servers {
            guard
                server.serverType == Server.ServerType.imap ||
                    server.serverType == Server.ServerType.smtp
                else {
                    Log.shared.errorAndCrash(component: #function,
                                             errorString: "Unsupported server type")
                    continue
            }
            let credentials = server.credentials
            if let emailConnectInfo = Account.emailConnectInfo(account: self,
                                                               server: server,
                                                               credentials: credentials) {
                result.append(emailConnectInfo)
            }
        }

        return result
    }

    /**
     - Returns: The first found IMAP connect info. Used by some tests.
     */
    var imapConnectInfo: EmailConnectInfo? {
        return emailConnectInfos().filter { return $0.emailProtocol == .imap }.first
    }

    /**
     - Returns: The first found SMTP connect info. Used by some tests.
     */
    var smtpConnectInfo: EmailConnectInfo? {
        return emailConnectInfos().filter { return $0.emailProtocol == .smtp }.first
    }

    static func emailConnectInfo(account: Account, server: Server,
                          credentials: ServerCredentials) -> EmailConnectInfo? {
        guard
            let emailProtocol = EmailProtocol(serverType: server.serverType),
            let connectionTransport = server.transport
            else {
                Log.shared.errorAndCrash(component: #function, errorString: "Missing emailProtocol")
                return nil
        }

        return EmailConnectInfo(account: account,
                                server: server,
                                credentials: credentials,
                                loginName: credentials.loginName,
                                loginPasswordKeyChainKey: credentials.key,
                                networkAddress: server.address,
                                networkPort: server.port,
                                networkAddressType: nil,
                                networkTransportType: nil,
                                emailProtocol: emailProtocol,
                                connectionTransport: ConnectionTransport(fromInt: Int(connectionTransport.rawValue)),
                                authMethod: AuthMethod(string: server.authMethod),
                                trusted: server.trusted)
    }
}
