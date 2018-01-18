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
        if let key = credentials.key {
            let serverType = server.serverType.asString()
            return (server, credentials, KeyChain.password(key: key, serverType: serverType))
        }
        return nil
    }

    private func emailConnectInfos() -> [(EmailConnectInfo, CdServerCredentials)] {
        var result = [(emailConnectInfo: EmailConnectInfo,
                       cdServerCredentials: CdServerCredentials)]()
        guard let cdServers = servers?.allObjects as? [CdServer] else {
            return result
        }

        let accessTokens = Dictionary<String, OAuth2AccessTokenProtocol>()
        for cdServer in cdServers {
            if cdServer.serverType == Server.ServerType.imap
                || cdServer.serverType == Server.ServerType.smtp  {
                guard let cdCredentials = cdServer.credentials else {
                        continue
                }
                if let emailConnectInfo = emailConnectInfo(
                    account: self, server: cdServer, credentials: cdCredentials,
                    accessTokens: accessTokens) {
                    result.append((emailConnectInfo, cdCredentials))
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
                          accessTokens: [String:OAuth2AccessTokenProtocol]) -> EmailConnectInfo? {
        var accessTokens = accessTokens
        var accessToken: OAuth2AccessTokenProtocol?
        if let authMethod = AuthMethod(string: server.authMethod),
            authMethod == .saslXoauth2,
            let password = credentials.password,
            let token = OAuth2AccessToken.from(base64Encoded: password) {
            accessToken = accessTokens[token.keyChainID] ?? token
            accessTokens[token.keyChainID] = accessToken
        }

        if let port = server.port?.int16Value,
            let address = server.address,
            let emailProtocol = EmailProtocol(serverType: server.serverType) {
            return EmailConnectInfo(
                accountObjectID: account.objectID, serverObjectID: server.objectID,
                credentialsObjectID: credentials.objectID,
                loginName: credentials.loginName,
                loginPassword: accessToken == nil ? credentials.password : nil,
                networkAddress: address, networkPort: UInt16(port),
                networkAddressType: nil,
                networkTransportType: nil, emailProtocol: emailProtocol,
                connectionTransport: ConnectionTransport(fromInt: Int(server.transportRawValue)),
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
