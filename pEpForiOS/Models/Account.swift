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
        case Imap = 0
        case Smtp = 1

        public func asString() -> String {
            switch self {
            case .Imap:
                return "IMAP"
            case .Smtp:
                return "SMTP"
            }
        }
    }

    public var connectInfo: ConnectInfo {
        return ConnectInfo.init(
            email: self.email, imapPassword: "",
            imapAuthMethod: AuthMethod.init(string: self.imapAuthMethod),
            smtpAuthMethod: AuthMethod.init(string: self.smtpAuthMethod),
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
