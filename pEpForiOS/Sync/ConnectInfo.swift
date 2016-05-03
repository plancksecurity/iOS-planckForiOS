//
//  ConnectInfo
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 08/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation

public enum ImapAuthMethod: String {
    case Login = "LOGIN"
    case CramMD5 = "CRAM-MD5"

    init(string: String) {
        if string.isEqual(Login.rawValue) {
            self = Login
        } else if string.isEqual(CramMD5.rawValue) {
            self = CramMD5
        } else {
            self = Login
            assert(false, "")
        }
    }
}

public enum SmtpAuthMethod: String {
    case Plain = "PLAIN"
    case Login = "LOGIN"
    case CramMD5 = "CRAM-MD5"

    init(string: String) {
        if string.isEqual(Plain.rawValue) {
            self = Plain
        } else if string.isEqual(Login.rawValue) {
            self = Login
        } else if string.isEqual(CramMD5.rawValue) {
            self = CramMD5
        } else {
            self = Plain
            assert(false, "")
        }
    }
}

/**
 Holds connection info (like server, port etc.) for IMAP and SMTP.
 */
public protocol IConnectInfo {
    var email: String { get }
    var imapUsername: String? { get }
    var smtpUsername: String? { get }
    var imapPassword: String? { get }
    var smtpPassword: String? { get }
    var imapAuthMethod: ImapAuthMethod { get }
    var smtpAuthMethod: SmtpAuthMethod { get }

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
    public let email: String
    public let imapUsername: String?
    public let smtpUsername: String?
    public let imapPassword: String?
    public let smtpPassword: String?
    public let imapAuthMethod: ImapAuthMethod
    public let smtpAuthMethod: SmtpAuthMethod
    public let imapServerName: String
    public let imapServerPort: UInt16
    public let imapTransport: ConnectionTransport
    public let smtpServerName: String
    public let smtpServerPort: UInt16
    public let smtpTransport: ConnectionTransport

    public var accountName: String {
        return email
    }

    public init(email: String, imapUsername: String?, smtpUsername: String?,
                imapPassword: String?, smtpPassword: String?,
                imapAuthMethod: ImapAuthMethod, smtpAuthMethod: SmtpAuthMethod,
                imapServerName: String, imapServerPort: UInt16, imapTransport: ConnectionTransport,
                smtpServerName: String, smtpServerPort: UInt16, smtpTransport: ConnectionTransport) {
        self.email = email
        self.imapUsername = imapUsername
        self.smtpUsername = smtpUsername
        self.imapPassword = imapPassword
        self.smtpPassword = smtpPassword
        self.imapAuthMethod = imapAuthMethod
        self.smtpAuthMethod = smtpAuthMethod
        self.imapServerName = imapServerName
        self.imapServerPort = imapServerPort
        self.imapTransport = imapTransport
        self.smtpServerName = smtpServerName
        self.smtpServerPort = smtpServerPort
        self.smtpTransport = smtpTransport
    }

    public init(email: String, imapPassword: String, imapAuthMethod: ImapAuthMethod,
                smtpAuthMethod: SmtpAuthMethod,
                imapServerName: String, imapServerPort: UInt16, imapTransport: ConnectionTransport,
                smtpServerName: String, smtpServerPort: UInt16, smtpTransport: ConnectionTransport) {
        self.email = email
        self.imapUsername = nil
        self.smtpUsername = nil
        self.imapPassword = imapPassword
        self.smtpPassword = nil
        self.imapAuthMethod = imapAuthMethod
        self.smtpAuthMethod = smtpAuthMethod
        self.imapServerName = imapServerName
        self.imapServerPort = imapServerPort
        self.imapTransport = imapTransport
        self.smtpServerName = smtpServerName
        self.smtpServerPort = smtpServerPort
        self.smtpTransport = smtpTransport
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

extension ConnectInfo: Hashable {
    public var hashValue: Int {
        return "\(email) \(imapUsername) \(smtpUsername) \(imapAuthMethod) \(smtpAuthMethod) \(imapServerName) \(imapServerPort) \(smtpServerName) \(smtpServerPort) \(imapTransport) \(smtpTransport)".hashValue
    }
}

extension ConnectInfo: Equatable {}

public func ==(l: ConnectInfo, r: ConnectInfo) -> Bool {
    return l.email == r.email && l.imapUsername == r.imapUsername &&
        l.imapTransport == r.imapTransport && l.imapAuthMethod == r.imapAuthMethod &&
        l.imapServerName == r.imapServerName && l.imapServerPort == r.imapServerPort &&
        l.smtpUsername == r.smtpUsername && l.smtpTransport == r.smtpTransport &&
        l.smtpAuthMethod == r.smtpAuthMethod && l.smtpTransport == r.smtpTransport &&
        l.smtpServerName == r.smtpServerName && l.smtpServerPort == r.smtpServerPort
}
