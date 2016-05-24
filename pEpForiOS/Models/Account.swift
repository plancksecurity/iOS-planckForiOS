import Foundation
import CoreData

public protocol IAccount: _IAccount {
    var connectInfo: ConnectInfo { get }
    var rawImapTransport: ConnectionTransport { get }
    var rawSmtpTransport: ConnectionTransport { get }
}

@objc(Account)
public class Account: _Account, IAccount {
    static let kSettingLastAccountEmail = "kSettingLastAccountEmail"

    public enum AccountType: Int {
        case IMAP = 0
        case SMTP = 1

        public func asString() -> String {
            switch self {
            case .IMAP:
                return "IMAP"
            case .SMTP:
                return "SMTP"
            }
        }
    }

    public var connectInfo: ConnectInfo {
        let passImap = KeyChain.getPassword(self.email, serverType: AccountType.IMAP.asString())
        let passSmtp = KeyChain.getPassword(self.email, serverType: AccountType.SMTP.asString())
        return ConnectInfo.init(
            email: email, imapUsername: imapUsername, smtpUsername: smtpUsername,
            imapPassword: passImap, smtpPassword: passSmtp,
            imapServerName: self.imapServerName,
            imapServerPort: UInt16(self.imapServerPort.integerValue),
            imapTransport: self.rawImapTransport,
            smtpServerName: self.smtpServerName,
            smtpServerPort: UInt16(self.smtpServerPort.integerValue),
            smtpTransport: self.rawSmtpTransport)
    }

    public var rawImapTransport: ConnectionTransport {
        return ConnectionTransport(rawValue: self.imapTransport.integerValue)!
    }

    public var rawSmtpTransport: ConnectionTransport {
        return ConnectionTransport(rawValue: self.smtpTransport.integerValue)!
    }
}
