//
//  CdAccount+Extension.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 17/10/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import MessageModel

extension CdAccount {
    private func emailConnectInfos() -> [EmailConnectInfo] {
        var result = [EmailConnectInfo]()
        guard let cdServers = servers?.allObjects as? [CdServer] else {
            return result
        }

        for cdServer in cdServers {
            guard
                cdServer.serverType == Server.ServerType.imap ||
                    cdServer.serverType == Server.ServerType.smtp
                else {
                    Log.shared.errorAndCrash(component: #function,
                                             errorString: "Unsupported server type")
                    continue
            }
            let server = cdServer.server()
            let credentials = server.credentials
            if let emailConnectInfo = emailConnectInfo(account: self.account(),
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

    func emailConnectInfo(account: Account, server: Server,
                          credentials: ServerCredentials) -> EmailConnectInfo? {
        guard
            let emailProtocol = EmailProtocol(serverType: server.serverType),
            let connectionTransport = server.transport,
            let authMethodRaw = server.authMethod
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
                                authMethod: AuthMethod(rawValue: authMethodRaw),
                                trusted: server.trusted)

        //IOS-1033: cleanup
//        if let port = server.port?.int16Value,
//            let address = server.address,
//            let emailProtocol = EmailProtocol(serverType: server.serverType) {
//            return EmailConnectInfo(
//                accountObjectID: account.objectID, serverObjectID: server.objectID,
//                credentialsObjectID: credentials.objectID,
//                loginName: credentials.loginName,
//                loginPasswordKeyChainKey: credentials.key,
//                networkAddress: address, networkPort: UInt16(port),
//                networkAddressType: nil,
//                networkTransportType: nil, emailProtocol: emailProtocol,
//                connectionTransport: ConnectionTransport(fromInt: Int(server.transportRawValue)),
//                authMethod: AuthMethod(string: server.authMethod),
//                trusted: server.trusted)
//        }
//        return nil
    }

    /**
     - Returns: A folder under this account with the given name.
     */
    open func folder(byName name: String) -> CdFolder? {
        return CdFolder.first(attributes: ["account": self, "name": name])
    }

    /**
     Check all credentials for their `needsVerification` status. If none need it anymore,
     the whole account gets updated too.
     */
    open func checkVerificationStatus() {
        guard let cdServers = servers?.allObjects as? [CdServer] else {
            return
        }
        var verificationStillNeeded = false
        for cdServer in cdServers {
            guard let creds = cdServer.credentials else {
                Log.shared.errorAndCrash(component: #function, errorString: "Server \(cdServer) has no credetials.")
                continue
            }
            if creds.needsVerification {
                verificationStillNeeded = true
            }
        }
        needsVerification = verificationStillNeeded
    }
}
