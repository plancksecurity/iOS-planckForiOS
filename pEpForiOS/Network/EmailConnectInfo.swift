//
//  EmailConnectInfo
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 08/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel

public extension ConnectionTransport {
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
        switch self {
        case .plain:
            return NSLocalizedString("None", comment: "Transport security (ConnectionTransport)")
        case .TLS:
            return NSLocalizedString("TLS", comment: "Transport security (ConnectionTransport)")
        case .startTLS:
            return NSLocalizedString("StartTLS",
                                     comment: "Transport security (ConnectionTransport)")
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

    init(string: String) {
        if string.isEqual(AuthMethod.Plain.rawValue) {
            self = .Plain
        } else if string.isEqual(AuthMethod.Login.rawValue) {
            self = .Login
        } else if string.isEqual(AuthMethod.CramMD5.rawValue) {
            self = .CramMD5
        } else {
            // To fail
            self = .Plain
            assert(false)
        }
    }
}

public enum EmailProtocol: String {
    case smtp = "SMTP"
    case imap = "IMAP"
    
    init(emailProtocol: String) {
        if emailProtocol.isEqual(EmailProtocol.smtp.rawValue) {
            self = .smtp
        } else if emailProtocol.isEqual(EmailProtocol.imap.rawValue) {
            self = .imap
        } else {
            // To fail
            self = .smtp
            assert(false)
        }
    }
}

/**
 Holds additional connection info (like server, port etc.) for IMAP and SMTP.
 */
public protocol IEmailConnectInfo: IConnectInfo {
    var emailProtocol: EmailProtocol? { get }
    var connectionTransport: ConnectionTransport? { get }
    var userPassword: String? { get }
    var authMethod: AuthMethod? { get }
}

public class EmailConnectInfo: ConnectInfo {
    public var emailProtocol: EmailProtocol?
    public var connectionTransport: ConnectionTransport?
    public var userPassword: String?
    public var authMethod: AuthMethod?
    
    public convenience init(emailProtocol: EmailProtocol,
                            userId: String,
                            userPassword: String? = nil,
                            userName: String? = nil,
                            networkPort: UInt16,
                            networkAddress: String,
                            connectionTransport: ConnectionTransport? = nil,
                            authMethod: AuthMethod? = nil)
    {
        self.init(emailProtocol: emailProtocol,
                  userId: userId,
                  userPassword: nil,
                  userName: nil,
                  networkPort: networkPort,
                  networkAddress: networkAddress,
                  connectionTransport: nil,
                  authMethod: nil)
    }
}
