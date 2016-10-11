import Foundation

@objc(CdAccount)
open class CdAccount: _CdAccount {
    let comp = "CdAccount"
    
    static let kSettingLastAccountEmail = "kSettingLastAccountEmail"

    public enum AccountType: Int {
        case imap = 0
        case smtp = 1

        public func asString() -> String {
            switch self {
            case .imap:
                return "IMAP"
            case .smtp:
                return "SMTP"
            }
        }
    }

    open var connectInfo: ConnectInfo {
        let passImap = KeyChain.getPassword(self.email, serverType: AccountType.imap.asString())
        let passSmtp = KeyChain.getPassword(self.email, serverType: AccountType.smtp.asString())
        return ConnectInfo.init(
            nameOfTheUser: nameOfTheUser,
            email: email, imapUsername: imapUsername, smtpUsername: smtpUsername,
            imapPassword: passImap, smtpPassword: passSmtp,
            imapServerName: self.imapServerName,
            imapServerPort: UInt16(self.imapServerPort.intValue),
            imapTransport: self.rawImapTransport,
            smtpServerName: self.smtpServerName,
            smtpServerPort: UInt16(self.smtpServerPort.intValue),
            smtpTransport: self.rawSmtpTransport)
    }

    open var rawImapTransport: ConnectionTransport {
        return ConnectionTransport(rawValue: self.imapTransport.intValue)!
    }

    open var rawSmtpTransport: ConnectionTransport {
        return ConnectionTransport(rawValue: self.smtpTransport.intValue)!
    }
}
