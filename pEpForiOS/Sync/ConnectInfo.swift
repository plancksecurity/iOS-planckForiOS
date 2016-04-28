//
//  ConnectInfo
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 08/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation

/**
 Holds connection info (like server, port etc.) for IMAP and SMTP.
 */
public class ConnectInfo: NSObject {
    public let email: String
    public let imapUsername: String?
    public let smtpUsername: String?
    public let imapPassword: String?
    public let smtpPassword: String?
    public let imapAuthMethod: String
    public let smtpAuthMethod: String
    public let imapServerName: String
    public let imapServerPort: UInt16
    public let smtpServerName: String
    public let smtpServerPort: UInt16
    public let imapTransport: ConnectionTransport
    public let smtpTransport: ConnectionTransport

    public var accountName: String {
        return email
    }

    public init(email: String,
         imapUsername: String?, smtpUsername: String?,
         imapPassword: String?, smtpPassword: String?,
         imapAuthMethod: String, smtpAuthMethod: String,
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

    public convenience init(email: String,
                     imapPassword: String,
                     imapAuthMethod: String, smtpAuthMethod: String,
                     imapServerName: String, imapServerPort: UInt16,
                     imapTransport: ConnectionTransport,
                     smtpServerName: String, smtpServerPort: UInt16,
                     smtpTransport: ConnectionTransport) {
        self.init(email: email, imapUsername: nil, smtpUsername: nil,
                  imapPassword: imapPassword, smtpPassword: nil,
                  imapAuthMethod: imapAuthMethod, smtpAuthMethod: smtpAuthMethod,
                  imapServerName: imapServerName, imapServerPort: imapServerPort,
                  imapTransport: imapTransport,
                  smtpServerName: smtpServerName, smtpServerPort: smtpServerPort,
                  smtpTransport: smtpTransport)
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