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
            self = .Plain
            assert(false, "")
        }
    }
}

/**
 Holds additional connection info (like server, port etc.) for IMAP and SMTP.
 */
public protocol IEmailConnectInfo: IConnectInfo {
    var userPassword: String? { get }
    var connectionTransport: ConnectionTransport { get }
}

public class EmailConnectInfo: ConnectInfo {
    public var userPassword: String?
    public var connectionTransport: ConnectionTransport?
    
    public convenience init(userId: String, userPassword: String? = nil, userName: String? = nil, connectionPort: UInt16, connectionAddress: String, connectionTransport: ConnectionTransport?)
    {
        self.init(userId: userId, userPassword: nil, userName: nil, connectionPort: connectionPort, connectionAddress: connectionAddress, connectionTransport: nil)
    }
}
