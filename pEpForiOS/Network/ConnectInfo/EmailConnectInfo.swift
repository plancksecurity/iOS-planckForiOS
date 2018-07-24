//
//  MMEmailConnectInfo.swift
//  pEp
//
//  Created by Andreas Buff on 23.07.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel

extension ConnectionTransport {
    init?(fromInt: Int?) {
        guard let i = fromInt else {
            return nil
        }
        switch i {
        case ConnectionTransport.plain.rawValue:
            self = ConnectionTransport.plain
        case ConnectionTransport.startTLS.rawValue:
            self = ConnectionTransport.startTLS
        case ConnectionTransport.TLS.rawValue:
            self = ConnectionTransport.TLS
        default:
            return nil
        }
    }

    static func fromInteger(_ i: Int) -> ConnectionTransport {
        switch i {
        case ConnectionTransport.plain.rawValue:
            return ConnectionTransport.plain
        case ConnectionTransport.startTLS.rawValue:
            return ConnectionTransport.startTLS
        case ConnectionTransport.TLS.rawValue:
            return ConnectionTransport.TLS
        default:
            abort()
        }
    }

    func localizedString() -> String {
        let transport_security_text = "Transport security (ConnectionTransport)"
        switch self {
        case .plain:
            return NSLocalizedString("None", comment: transport_security_text)
        case .TLS:
            return NSLocalizedString("TLS", comment: transport_security_text)
        case .startTLS:
            return NSLocalizedString("StartTLS", comment: transport_security_text)
        }
    }

    // XXX: Here material from the Model area is used: to be avoided or code-shared.
    func toServerTransport() -> Server.Transport {
        switch self {
        case .plain: return Server.Transport.plain
        case .TLS: return Server.Transport.tls
        case .startTLS: return Server.Transport.startTls
        }
    }
}

enum EmailProtocol: String {
    case smtp = "SMTP"
    case imap = "IMAP"

    init?(emailProtocol: String) {
        if emailProtocol.isEqual(EmailProtocol.smtp.rawValue) {
            self = .smtp
        } else if emailProtocol.isEqual(EmailProtocol.imap.rawValue) {
            self = .imap
        } else {
            return nil
        }
    }

    init?(serverType: Server.ServerType?) {
        guard let st = serverType else {
            return nil
        }
        switch st {
        case .imap:
            self = .imap
        case .smtp:
            self = .smtp
        }
    }
}

class EmailConnectInfo: ConnectInfo {
    enum EmailConnectInfoError: Error {
        case cannotFindServerCredentials
    }

    let emailProtocol: EmailProtocol?
    let connectionTransport: ConnectionTransport?
    let authMethod: AuthMethod?
    let trusted: Bool

    /**
     There is either the `loginPassword`, or this, but there should never exist both.
     If non-nil, the `authMethod` is expected to be `AuthMethod.saslXoauth2`.
     */
    var accessToken: OAuth2AccessTokenProtocol? {
        guard authMethod == .saslXoauth2,
            let key = loginPasswordKeyChainKey,
            let token = KeyChain.serverPassword(forKey: key) else {
                return nil
        }
        return OAuth2AccessToken.from(base64Encoded: token) as? OAuth2AccessTokenProtocol
    }

    init(account: Account,
                server: Server,
                credentials: ServerCredentials,
                loginName: String? = nil,
                loginPasswordKeyChainKey: String? = nil,
                networkAddress: String,
                networkPort: UInt16,
                networkAddressType: NetworkAddressType? = nil,
                networkTransportType: NetworkTransportType? = nil,
                emailProtocol: EmailProtocol? = nil,
                connectionTransport: ConnectionTransport? = nil,
                authMethod: AuthMethod? = nil,
                trusted: Bool = false) {
        self.emailProtocol = emailProtocol
        self.connectionTransport = connectionTransport
        self.authMethod = authMethod
        self.trusted = trusted

        super.init(account: account,
                   server: server,
                   credentials: credentials,
                   loginName: loginName,
                   loginPasswordKeyChainKey: loginPasswordKeyChainKey,
                   networkAddress: networkAddress,
                   networkPort: networkPort,
                   networkAddressType: networkAddressType,
                   networkTransportType: networkTransportType)
    }

    //    func unsetNeedsVerificationAndFinish(context: NSManagedObjectContext) -> Error? {
    //        guard let creds = context.object(
    //            with: self.credentialsObjectID)
    //            as? CdServerCredentials else {
    //                return EmailConnectInfoError.cannotFindServerCredentials
    //        }
    //
    //        if creds.needsVerification == true {
    //            creds.needsVerification = false
    //            if let cdAccount = creds.account {
    //                cdAccount.checkVerificationStatus()
    //            }
    //            context.saveAndLogErrors()
    //        }
    //        return nil
    //    }

    override var hashValue: Int {
        return super.hashValue &+ (emailProtocol?.hashValue ?? 0)
            &+ (connectionTransport?.hashValue ?? 0)
            &+ (authMethod?.hashValue ?? 0)
            &+ trusted.hashValue
    }
}

func ==(l: EmailConnectInfo, r: EmailConnectInfo) -> Bool {
    let sl = l as ConnectInfo
    let sr = r as ConnectInfo
    return sl == sr &&
        l.connectionTransport == r.connectionTransport &&
        l.authMethod == r.authMethod &&
        l.trusted == r.trusted
}
