//
//  ConnectInfo
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
 Holds connection info (like server, port etc.) for IMAP and SMTP.
 */
public protocol IConnectInfo: Hashable {
    var email: String { get }
    var imapUsername: String? { get }
    var smtpUsername: String? { get }
    var imapPassword: String? { get }
    var smtpPassword: String? { get }

    var imapServerName: String { get }
    var imapServerPort: UInt16 { get }
    var smtpServerName: String { get }
    var smtpServerPort: UInt16 { get }
    var imapTransport: ConnectionTransport { get }
    var smtpTransport: ConnectionTransport { get }

    var accountName: String { get }

    func getSmtpUsername() -> String

    func getImapUsername() -> String

    func getSmtpPassword() -> String?
}

public struct ConnectInfo: IConnectInfo {
    public var nameOfTheUser: String
    public var email: String
    public var imapUsername: String?
    public var smtpUsername: String?
    public var imapPassword: String?
    public var smtpPassword: String?
    public var imapServerName: String
    public var imapServerPort: UInt16 = 993
    public var imapTransport: ConnectionTransport = .TLS
    public var smtpServerName: String
    public var smtpServerPort: UInt16 = 587
    public var smtpTransport: ConnectionTransport = .startTLS

    public var accountName: String {
        return email
    }

    public func getSmtpUsername() -> String {
        if let username = smtpUsername {
            return username
        }
        return getImapUsername()
    }

    public func getImapUsername() -> String {
        if let username = imapUsername {
            return username
        }
        return email
    }

    public func getSmtpPassword() -> String? {
        if let password = smtpPassword {
            return password
        }
        return imapPassword
    }
}

public extension ConnectInfo {
    public init(nameOfTheUser: String, email: String, imapPassword: String? = nil,
                imapServerName: String, imapServerPort: UInt16 = 993,
                imapTransport: ConnectionTransport = .TLS,
                smtpServerName: String, smtpServerPort: UInt16 = 587,
                smtpTransport: ConnectionTransport = .startTLS)
    {
        self.init(nameOfTheUser: nameOfTheUser, email: email, imapUsername: nil, smtpUsername: nil,
                  imapPassword: imapPassword, smtpPassword: nil,
                  imapServerName: imapServerName, imapServerPort: imapServerPort,
                  imapTransport: imapTransport, smtpServerName: smtpServerName,
                  smtpServerPort: smtpServerPort, smtpTransport: smtpTransport)
    }
}

extension ConnectInfo: Hashable {
    public var hashValue: Int {
        return 31 &* email.hashValue &+
            MiscUtil.optionalHashValue(imapUsername) &+
            MiscUtil.optionalHashValue(smtpUsername) &+
            MiscUtil.optionalHashValue(imapServerName) &+
            MiscUtil.optionalHashValue(imapServerPort) &+
            MiscUtil.optionalHashValue(smtpServerName) &+
            MiscUtil.optionalHashValue(smtpServerPort) &+
            MiscUtil.optionalHashValue(imapTransport) &+
            MiscUtil.optionalHashValue(smtpTransport)
    }
}

extension ConnectInfo: Equatable {}

public func ==(l: ConnectInfo, r: ConnectInfo) -> Bool {
    return l.nameOfTheUser == r.nameOfTheUser && l.email == r.email &&
        l.imapUsername == r.imapUsername &&
        l.imapTransport == r.imapTransport &&
        l.imapServerName == r.imapServerName && l.imapServerPort == r.imapServerPort &&
        l.smtpUsername == r.smtpUsername && l.smtpTransport == r.smtpTransport &&
        l.smtpTransport == r.smtpTransport &&
        l.smtpServerName == r.smtpServerName && l.smtpServerPort == r.smtpServerPort
}
