//
//  Model.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 02/05/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation
import CoreData

public protocol IModel {
    func existingMessage(msg: CWIMAPMessage) -> IMessage?
    func messageByPredicate(predicate: NSPredicate) -> IMessage?
    func messagesByPredicate(predicate: NSPredicate) -> [IMessage]?
    func messageCountByPredicate(predicate: NSPredicate) -> Int

    func folderCountByPredicate(predicate: NSPredicate) -> Int
    func foldersByPredicate(predicate: NSPredicate) -> [IFolder]?
    func folderByPredicate(predicate: NSPredicate) -> IFolder?
    func folderByName(name: String, email: String) -> IFolder?
    func folderByName(name: String, email: String, folderType: Account.AccountType) -> IFolder?

    func accountByEmail(email: String) -> IAccount?
    func setAccountAsLastUsed(account: IAccount) -> IAccount
    func fetchLastAccount() -> IAccount?

    func insertAccountFromConnectInfo(connectInfo: ConnectInfo) -> IAccount?
    func insertNewMessage() -> IMessage
    func insertTestAccount() -> IAccount?

    func insertOrUpdateContactEmail(email: String, name: String?) -> IContact?

    /**
     Inserts a folder of the given type.
     - Note: Caller is responsible for saving!
     */
    func insertOrUpdateFolderName(folderName: String,
                                  folderType: Account.AccountType,
                                  accountEmail: String) -> IFolder?

    func save()

    /**
     For debugging: Dumps some important DB contents.
     */
    func dumpDB()
}

public class Model: IModel {
    let comp = "Model"

    public static let CouldNotCreateFolder = 1000

    let context: NSManagedObjectContext

    public init(context: NSManagedObjectContext) {
        self.context = context
    }

    func singleEntityWithName(name: String, predicate: NSPredicate) -> NSManagedObject? {
        let fetch = NSFetchRequest.init(entityName: name)
        fetch.predicate = predicate
        do {
            let objs = try context.executeFetchRequest(fetch)
            if objs.count == 1 {
                return objs[0] as? NSManagedObject
            } else if objs.count == 0 {
                return nil
            } else {
                Log.warn(comp, "Several objects (\(name)) found for predicate: \(predicate)")
                return objs[0] as? NSManagedObject
            }
        } catch let err as NSError {
            Log.error(comp, error: err)
        }
        return nil
    }

    public func entitiesWithName(name: String,
                                 predicate: NSPredicate) -> [NSManagedObject]? {
        let fetch = NSFetchRequest.init(entityName: name)
        fetch.predicate = predicate
        do {
            let objs = try context.executeFetchRequest(fetch)
            return objs as? [NSManagedObject]
        } catch let err as NSError {
            Log.error(comp, error: err)
        }
        return nil
    }

    public func countWithName(name: String,
                              predicate: NSPredicate) -> Int {
        let fetch = NSFetchRequest.init(entityName: name)
        fetch.predicate = predicate
        var error: NSError?
        let number = context.countForFetchRequest(fetch, error: &error)
        if let err = error {
            Log.error(comp, error: err)
        }
        if number != NSNotFound {
            return number
        }
        return 0
    }
    public func existingMessage(msg: CWIMAPMessage) -> IMessage? {
        var predicates: [NSPredicate] = []
        if let msgId = msg.messageID() {
            predicates.append(NSPredicate.init(format: "messageId = %@", msgId))
        }
        if msg.folder() != nil {
            predicates.append(NSPredicate.init(format: "uid = %d and folder.name = %@",
                msg.UID(), msg.folder()!.name()))
        }
        if msg.subject() != nil && msg.receivedDate() != nil {
            predicates.append(NSPredicate.init(format: "subject = %@ and originationDate = %@",
                msg.subject()!, msg.receivedDate()!))
        }
        let pred = NSCompoundPredicate.init(andPredicateWithSubpredicates: predicates)
        if let mail = singleEntityWithName(Message.entityName(), predicate: pred) {
            let result = mail as! Message
            return result
        }
        return nil
    }

    func newAccountFromConnectInfo(connectInfo: ConnectInfo) -> IAccount {
        let account = NSEntityDescription.insertNewObjectForEntityForName(
            Account.entityName(), inManagedObjectContext: context) as! Account

        account.email = connectInfo.email
        account.imapUsername = connectInfo.imapUsername
        account.smtpUsername = connectInfo.smtpUsername
        account.imapServerName = connectInfo.imapServerName
        account.smtpServerName = connectInfo.smtpServerName
        account.imapServerPort = NSNumber.init(short: Int16(connectInfo.imapServerPort))
        account.smtpServerPort = NSNumber.init(short: Int16(connectInfo.smtpServerPort))
        account.imapTransport = NSNumber.init(short: Int16(connectInfo.imapTransport.rawValue))
        account.smtpTransport = NSNumber.init(short: Int16(connectInfo.smtpTransport.rawValue))

        return account
    }

    public func insertAccountFromConnectInfo(connectInfo: ConnectInfo) -> IAccount? {
        let account = newAccountFromConnectInfo(connectInfo)
        save()
        KeyChain.addEmail(connectInfo.email, serverType: Account.AccountType.Imap.asString(),
                          password: connectInfo.imapPassword!)
        KeyChain.addEmail(connectInfo.email, serverType: Account.AccountType.Smtp.asString(),
                          password: connectInfo.getSmtpPassword()!)
        return account
    }

    public func insertNewMessage() -> IMessage {
        let mail = NSEntityDescription.insertNewObjectForEntityForName(
            Message.entityName(), inManagedObjectContext: context) as! Message
        return mail
    }

    public func insertTestAccount() -> IAccount? {
        if let account = insertAccountFromConnectInfo(TestData.connectInfo) {
            return setAccountAsLastUsed(account)
        } else {
            return nil
        }
    }

    public func setAccountAsLastUsed(account: IAccount) -> IAccount {
        NSUserDefaults.standardUserDefaults().setObject(
            account.email, forKey: Account.kSettingLastAccountEmail)
        NSUserDefaults.standardUserDefaults().synchronize()
        return account
    }

    public func fetchLastAccount() -> IAccount? {
        let lastEmail = NSUserDefaults.standardUserDefaults().stringForKey(
            Account.kSettingLastAccountEmail)

        var predicate = NSPredicate.init(value: true)

        if lastEmail?.characters.count > 0 {
            predicate = NSPredicate.init(format: "email == %@", lastEmail!)
        }

        if let account = singleEntityWithName(Account.entityName(), predicate: predicate) {
            return setAccountAsLastUsed(account as! Account)
        } else {
            return nil
        }
    }

    public func accountByEmail(email: String) -> IAccount? {
        let predicate = NSPredicate.init(format: "email = %@", email)
        return singleEntityWithName(Account.entityName(), predicate: predicate)
            as? Account
    }

    public func save() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                Log.error(CoreDataUtil.comp, error: nserror)
                abort()
            }
        }
    }

    func folderPredicateByName(name: String, email: String) -> NSPredicate {
        return NSPredicate.init(format: "account.email = %@ and name = %@", email, name)
    }

    public func insertOrUpdateFolderName(
        folderName: String, folderType: Account.AccountType,
        accountEmail: String) -> IFolder? {
        if let folder = folderByName(folderName, email: accountEmail) {
            return folder
        }

        if let account = accountByEmail(accountEmail) {
            var folder = insertFolderName(folderName, email: accountEmail)
            folder.account = account as! Account
            folder.name = folderName
            folder.folderType = folderType.rawValue
            return folder
        }
        return nil
    }

    public func messageByPredicate(predicate: NSPredicate) -> IMessage? {
        return singleEntityWithName(Message.entityName(), predicate: predicate) as? Message
    }

    public func messagesByPredicate(predicate: NSPredicate) -> [IMessage]? {
        return entitiesWithName(Message.entityName(), predicate: predicate)?.map() {$0 as! Message}
    }

    public func messageCountByPredicate(predicate: NSPredicate) -> Int {
        return countWithName(Message.entityName(), predicate: predicate)
    }

    public func folderCountByPredicate(predicate: NSPredicate) -> Int {
        return countWithName(Folder.entityName(), predicate: predicate)
    }

    public func foldersByPredicate(predicate: NSPredicate) -> [IFolder]? {
        return entitiesWithName(Folder.entityName(), predicate: predicate)?.map() {$0 as! Folder}
    }

    public func folderByPredicate(predicate: NSPredicate) -> IFolder? {
        return singleEntityWithName(Folder.entityName(), predicate: predicate) as? Folder
    }

    public func folderByName(name: String, email: String) -> IFolder? {
        return folderByPredicate(folderPredicateByName(name, email: email))
    }

    public func folderByName(
        name: String, email: String, folderType: Account.AccountType) -> IFolder? {
        let p1 = folderPredicateByName(name, email: email)
        let p2 = NSPredicate.init(format: "folderType = %d", folderType.rawValue)
        let p = NSCompoundPredicate.init(andPredicateWithSubpredicates: [p1, p2])
        return folderByPredicate(p)
    }

    public func insertFolderName(name: String, email: String) -> IFolder {
        let folder = NSEntityDescription.insertNewObjectForEntityForName(
            Folder.entityName(), inManagedObjectContext: context) as! Folder
        folder.name = name
        if let account = accountByEmail(email) as? Account {
            folder.account = account
        }
        return folder
    }

    public func insertOrUpdateContactEmail(email: String, name: String?) -> IContact? {
        let fetch = NSFetchRequest.init(entityName:Contact.entityName())
        fetch.predicate = NSPredicate.init(format: "email == %@", email)
        do {
            var existing = try context.executeFetchRequest(fetch) as! [Contact]
            if existing.count > 1 {
                Log.warn(comp, "Duplicate contacts with address \(email)")
                existing[0].updateFromEmail(email, name: name)
                return existing[0]
            } else if existing.count == 1 {
                existing[0].updateFromEmail(email, name: name)
                return existing[0]
            } else {
                var contact = NSEntityDescription.insertNewObjectForEntityForName(
                    Contact.entityName(), inManagedObjectContext: context) as! Contact
                contact.updateFromEmail(email, name: name)
                return contact
            }
        } catch let err as NSError {
            Log.error(comp, error: err)
            return nil
        }
    }

    public func dumpDB() {
        if let folders = foldersByPredicate(NSPredicate.init(value: true)) {
            for folder in folders {
                Log.info(comp, "Folder \(folder.name) \(folder.messages.count) messages accountType \(folder.account.accountType)")
            }
        }

        if let messages = messagesByPredicate(NSPredicate.init(value: true)) {
            for msg in messages {
                Log.info(comp, "Message \(msg.uid) folder \(msg.folder.name) folder.count \(msg.folder.messages.count) accountType \(msg.folder.account.accountType)")
            }
        }
    }

}