import Foundation
import CoreData

@objc(Account)
public class Account: _Account {
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

    var connectInfo: ConnectInfo {
        return ConnectInfo.init(
            email: self.email, imapPassword: "",
            imapAuthMethod: self.imapAuthMethod, smtpAuthMethod: self.smtpAuthMethod,
            imapServerName: self.imapServerName,
            imapServerPort: UInt16(self.imapServerPort!.integerValue),
            imapTransport: self.rawImapTransport,
            smtpServerName: self.smtpServerName,
            smtpServerPort: UInt16(self.smtpServerPort!.integerValue),
            smtpTransport: self.rawSmtpTransport)
    }

    var rawImapTransport: ConnectionTransport {
        guard let v = self.imapTransport?.integerValue else {
            abort()
        }
        return ConnectionTransport(rawValue: v)!
    }

    var rawSmtpTransport: ConnectionTransport {
        guard let v = self.smtpTransport?.integerValue else {
            abort()
        }
        return ConnectionTransport(rawValue: v)!
    }

    public static func newAccountFromConnectInfo(connectInfo: ConnectInfo,
                                          context: NSManagedObjectContext) -> Account {
        let account = NSEntityDescription.insertNewObjectForEntityForName(
            entityName(), inManagedObjectContext: context) as! Account

        account.email = connectInfo.email
        account.imapUsername = connectInfo.imapUsername
        account.smtpUsername = connectInfo.smtpUsername
        account.imapAuthMethod = connectInfo.imapAuthMethod
        account.smtpAuthMethod = connectInfo.smtpAuthMethod
        account.imapServerName = connectInfo.imapServerName
        account.smtpServerName = connectInfo.smtpServerName
        account.imapServerPort = NSNumber.init(short: Int16(connectInfo.imapServerPort))
        account.smtpServerPort = NSNumber.init(short: Int16(connectInfo.smtpServerPort))
        account.imapTransport = NSNumber.init(short: Int16(connectInfo.imapTransport.rawValue))
        account.smtpTransport = NSNumber.init(short: Int16(connectInfo.smtpTransport.rawValue))

        return account
    }

    public static func fetchLastAccount(context: NSManagedObjectContext) -> Account? {
        let lastEmail = NSUserDefaults.standardUserDefaults().stringForKey(
            Account.kSettingLastAccountEmail)

        var predicate = NSPredicate.init(value: true)

        if lastEmail?.characters.count > 0 {
            predicate = NSPredicate.init(format: "email == %@", lastEmail!)
        }

        if let account = singleEntityWithName(entityName(), predicate: predicate,
                                              context: context) {
            return setAccountAsLastUsed(account as! Account)
        } else {
            return insertTestAccount(context)
        }
    }

    public static func setAccountAsLastUsed(account: Account) -> Account {
        NSUserDefaults.standardUserDefaults().setObject(
            account.email, forKey: Account.kSettingLastAccountEmail)
        NSUserDefaults.standardUserDefaults().synchronize()
        return account
    }

    public static func insertAccountFromConnectInfo(
        connectInfo: ConnectInfo, context: NSManagedObjectContext) -> Account? {
        let account = Account.newAccountFromConnectInfo(connectInfo, context: context)
        CoreDataUtil.saveContext(managedObjectContext: context)
        KeyChain.addEmail(connectInfo.email, serverType: Account.AccountType.Imap.asString(),
                          password: connectInfo.imapPassword)
        KeyChain.addEmail(connectInfo.email, serverType: Account.AccountType.Smtp.asString(),
                          password: connectInfo.getSmtpPassword())
        return account
    }

    static func insertTestAccount(context: NSManagedObjectContext) -> Account? {
        if let account = insertAccountFromConnectInfo(TestData(), context: context) {
            return setAccountAsLastUsed(account)
        } else {
            return nil
        }
    }

    public static func byEmail(email: String, context: NSManagedObjectContext) -> Account? {
        let predicate = NSPredicate.init(format: "email = %@", email)
        return singleEntityWithName(Account.entityName(), predicate: predicate,
                                  context: context) as! Account?
    }

}
