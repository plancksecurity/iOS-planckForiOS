//
//  CdAccount+Extension.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 17/10/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import MessageModel

extension CdAccount {
    func serverNTuple(credentials: CdServerCredentials,
                      server: CdServer) -> (CdServer, CdServerCredentials, String?)? {
        if let serverType = Server.ServerType.init(rawValue: Int(server.serverType))?.asString(),
            let key = credentials.key {
            return (server, credentials, KeyChain.password(key: key, serverType: serverType))
        }
        return nil
    }

    private func emailConnectInfos() -> [(EmailConnectInfo, CdServerCredentials)] {
        var result = [(emailConnectInfo: EmailConnectInfo,
                       cdServerCredentials: CdServerCredentials)]()

        guard let creds = credentials?.array as? [CdServerCredentials] else {
            return result
        }
        for cred in creds {
            if let servers = cred.servers?.sortedArray(using: []) as? [CdServer] {
                for server in servers {
                    let st = Int(server.serverType)
                    if st == Server.ServerType.imap.rawValue ||
                        st == Server.ServerType.smtp.rawValue {
                        let password = cred.password
                        if let emailConnectInfo = emailConnectInfo(
                            account: self, server: server, credentials: cred,
                            password: password) {
                            result.append((emailConnectInfo, cred))
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
        return emailConnectInfos().filter { return $0.0.emailProtocol == .imap }.first?.0
    }

    /**
     - Returns: The first found SMTP connect info. Used by some tests.
     */
    open var smtpConnectInfo: EmailConnectInfo? {
        return emailConnectInfos().filter { return $0.0.emailProtocol == .smtp }.first?.0
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
                credentialsObjectID: credentials.objectID,
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
        return CdFolder.first(attributes: ["account": self, "name": name])
    }

    /**
     Check all credentials for their `needsVerification` status. If none need it anymore,
     the whole account gets updated too.
     */
    open func checkVerificationStatus() {
        let creds = credentials?.array as? [CdServerCredentials] ?? []
        var verificationStillNeeded = false
        for theCred in creds {
            if theCred.needsVerification {
                verificationStillNeeded = true
            }
        }
        needsVerification = verificationStillNeeded
    }
}
