//
//  EmailConnectInfo
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 08/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation

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
    var emailProtocol: EmailProtocol { get }
    
    var connectionTransport: ConnectionTransport? { get }
    var userPassword: String? { get }
    var authMethod: AuthMethod? { get }
}

public class EmailConnectInfo: ConnectInfo {
    public var emailProtocol: EmailProtocol

    public var connectionTransport: ConnectionTransport?
    public var userPassword: String?
    public var authMethod: AuthMethod?
    
    public convenience init(emailProtocol: EmailProtocol,
                            userId: String,
                            userPassword: String? = nil,
                            userName: String? = nil,
                            connectionPort: UInt16,
                            connectionAddress: String,
                            connectionTransport: ConnectionTransport? = nil,
                            authMethod: AuthMethod? = nil)
    {
        self.init(emailProtocol: emailProtocol,
                  userId: userId,
                  userPassword: nil,
                  userName: nil,
                  connectionPort: connectionPort,
                  connectionAddress: connectionAddress,
                  connectionTransport: nil,
                  authMethod: nil)
    }
}
