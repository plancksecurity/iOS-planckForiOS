//
//  EmailConnectInfo
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 08/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import CoreData

import MessageModel

public extension ConnectionTransport {
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

    static public func fromInteger(_ i: Int) -> ConnectionTransport {
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
    
    public func localizedString() -> String {
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
    public func toServerTransport() -> Server.Transport {
        switch self {
        case .plain: return Server.Transport.plain
        case .TLS: return Server.Transport.tls
        case .startTLS: return Server.Transport.startTls
        }
    }

}

// This enum also exists in the MessageModel: to be put to a third (shared code) place.
public enum Transport: Int {
    case plain
    case tls
    case startTls
}

public enum AuthMethod: String {
    case Plain = "PLAIN"
    case Login = "LOGIN"
    case CramMD5 = "CRAM-MD5"

    init?(string: String?) {
        guard let s = string else {
            return nil
        }
        if s.isEqual(AuthMethod.Plain.rawValue) {
            self = .Plain
        } else if s.isEqual(AuthMethod.Login.rawValue) {
            self = .Login
        } else if s.isEqual(AuthMethod.CramMD5.rawValue) {
            self = .CramMD5
        } else {
            return nil
        }
    }
}

public enum EmailProtocol: String {
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

/**
 Holds additional connection info (like server, port etc.) for IMAP and SMTP.
 */
public class EmailConnectInfo: ConnectInfo {
    public var userPassword: String?

    public var emailProtocol: EmailProtocol?
    public var connectionTransport: ConnectionTransport?
    public var authMethod: AuthMethod?
    public var trusted: Bool

    public init(accountObjectID: NSManagedObjectID, serverObjectID: NSManagedObjectID,
                loginName: String? = nil,
                loginPassword: String? = nil,
                networkAddress: String,
                networkPort: UInt16, networkAddressType: NetworkAddressType? = nil,
                networkTransportType: NetworkTransportType? = nil,
                emailProtocol: EmailProtocol? = nil,
                connectionTransport: ConnectionTransport? = nil, authMethod: AuthMethod? = nil,
                trusted: Bool = false) {
        self.trusted = trusted
        super.init(accountObjectID: accountObjectID, serverObjectID: serverObjectID,
                   loginName: loginName,
                   loginPassword: loginPassword,
                   networkAddress: networkAddress,
                   networkPort: networkPort,
                   networkAddressType: networkAddressType,
                   networkTransportType: networkTransportType)
        self.emailProtocol = emailProtocol
        self.connectionTransport = connectionTransport
        self.userPassword = loginPassword
        self.authMethod = authMethod
    }
}
