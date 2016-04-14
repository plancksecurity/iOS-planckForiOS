import Foundation
import CoreData

@objc(Account)
public class Account: _Account {
    static let comp = "Account"

    static let kSettingLastAccountEmail = "kSettingLastAccountEmail"

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
            "Account", inManagedObjectContext: context) as! Account

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

    static func fetchLastAccount(context: NSManagedObjectContext) -> Account {
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

    static func insertTestAccount(context: NSManagedObjectContext) -> Account {
        let account = Account.newAccountFromConnectInfo(TestData(), context: context)
        do {
            try context.save()
        } catch let e as NSError {
            Log.error(comp, error: e)
        }
        return setAccountAsLastUsed(account)
    }

}
