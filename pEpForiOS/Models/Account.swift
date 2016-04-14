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

    static let comp = "Account"

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

    static func newAccountFromConnectInfo(connectInfo: ConnectInfo,
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

    static func fetchLastAccount(context: NSManagedObjectContext) -> Account? {
        let lastEmail = NSUserDefaults.standardUserDefaults().stringForKey(
            Account.kSettingLastAccountEmail)

        let request = NSFetchRequest.init(entityName: Account.entityName())
        if lastEmail?.characters.count > 0 {
            let predicate = NSPredicate.init(format: "email == %@", lastEmail!)
            request.predicate = predicate
        }

        do {
            let accounts = try context.executeFetchRequest(request)
            if accounts.count > 0 {
                return setAccountAsLastUsed(accounts[0] as! Account)
            } else {
                return insertTestAccount(context)
            }
        } catch let e as NSError {
            Log.error(Account.comp, error: e)
            return insertTestAccount(context)
        }
    }

    static func setAccountAsLastUsed(account: Account) -> Account {
        NSUserDefaults.standardUserDefaults().setObject(
            account.email, forKey: Account.kSettingLastAccountEmail)
        NSUserDefaults.standardUserDefaults().synchronize()
        return account
    }

    static func insertAccountFromConnectInfo(
        connectInfo: ConnectInfo, context: NSManagedObjectContext) -> Account? {
        let account = Account.newAccountFromConnectInfo(connectInfo, context: context)
        do {
            try context.save()
            KeyChain.addEmail(connectInfo.email, serverType: Account.AccountType.Imap.asString(),
                              password: connectInfo.imapPassword)
            KeyChain.addEmail(connectInfo.email, serverType: Account.AccountType.Smtp.asString(),
                              password: connectInfo.getSmtpPassword())
            return account
        } catch let e as NSError {
            Log.error(comp, error: e)
        }
        return nil
    }

    static func insertTestAccount(context: NSManagedObjectContext) -> Account? {
        if let account = insertAccountFromConnectInfo(TestData(), context: context) {
            return setAccountAsLastUsed(account)
        } else {
            return nil
        }
    }

    static func accountByEmail(email: String, context: NSManagedObjectContext) -> Account? {
        let fetchAccount = NSFetchRequest.init(entityName: Account.entityName())
        fetchAccount.predicate = NSPredicate.init(format: "email = %@", email)
        do {
            let accounts = try context.executeFetchRequest(fetchAccount)
            if accounts.count == 1 {
                let account: Account = accounts[0] as! Account
                return account
            } else if accounts.count == 0 {
                Log.warn(comp, "No account found for email: \(email)")
            } else {
                Log.warn(comp, "Several accounts found for email: \(email)")
            }
        } catch let err as NSError {
            Log.error(comp, error: err)
        }
        return nil
    }

    static func insertOrUpdateFolderWithName(folderName: String,
                                             folderType: AccountType,
                                             accountEmail: String,
                                             context: NSManagedObjectContext) -> Folder? {
        let p = NSPredicate.init(format: "account.email = %@ and name = %@", accountEmail,
                                 folderName)
        let fetch = NSFetchRequest.init(entityName: Folder.entityName())
        fetch.predicate = p
        do {
            let folders = try context.executeFetchRequest(fetch)
            if folders.count > 1 {
                Log.warn(comp, "Duplicate foldername \(folderName) for \(accountEmail)")
            } else if folders.count == 1 {
                let folder: Folder = folders[0] as! Folder
                return folder
            } else {
                if let account = self.accountByEmail(accountEmail, context: context) {
                    let folder = NSEntityDescription.insertNewObjectForEntityForName(
                        Folder.entityName(), inManagedObjectContext: context) as! Folder
                    folder.account = account
                    folder.name = folderName
                    folder.folderType = folderType.rawValue
                    try context.save()
                    return folder
                }
            }
        } catch let err as NSError {
            Log.error(comp, error: err)
        }
        return nil
    }

}
