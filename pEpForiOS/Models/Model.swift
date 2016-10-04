//
//  Model.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 02/05/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation
import CoreData
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


public protocol IModel {
    var context: NSManagedObjectContext { get }

    /**
     Retrieve a contact by email, without updating anything.
     */
    func contactByEmail(_ email: String) -> IContact?

    func contactsByPredicate(_ predicate: NSPredicate?,
                             sortDescriptors: [NSSortDescriptor]?) -> [IContact]?

    func existingMessage(_ msg: CWIMAPMessage) -> IMessage?
    func messageByPredicate(_ predicate: NSPredicate?,
                            sortDescriptors: [NSSortDescriptor]?) -> IMessage?
    func messagesByPredicate(_ predicate: NSPredicate?,
                             sortDescriptors: [NSSortDescriptor]?) -> [IMessage]?
    func messageCountByPredicate(_ predicate: NSPredicate?) -> Int

    /**
     - Returns: A message with the given UID and folder name, if found.
     */
    func messageByUID(_ uid: Int, folderName: String) -> IMessage?

    /**
     - Returns: The highest UID of the messages in the given folder.
     */
    func lastUidInFolderNamed(_ folderName: String) -> UInt

    func folderCountByPredicate(_ predicate: NSPredicate?) -> Int
    func foldersByPredicate(_ predicate: NSPredicate?,
                            sortDescriptors: [NSSortDescriptor]?) -> [IFolder]?
    func folderByPredicate(_ predicate: NSPredicate?,
                           sortDescriptors: [NSSortDescriptor]?) -> IFolder?

    /**
     Fetch a folder by name and account email.
     Will not return folders that are scheduled for deletion (where `shouldDelete` is true).
     */
    func folderByName(_ name: String, email: String) -> IFolder?

    /**
     Fetch a folder by name and account email, and type.
     Will not return folders that are scheduled for deletion (where `shouldDelete` is true).
     */
    func folderByName(_ name: String, email: String, folderType: Account.AccountType) -> IFolder?

    /**
     Fetch a folder by name and account email, even those scheduled for deletion
     (where `shouldDelete` is true).
     */
    func anyFolderByName(_ name: String, email: String) -> IFolder?

    func foldersForAccountEmail(_ accountEmail: String, predicate: NSPredicate?,
                                sortDescriptors: [NSSortDescriptor]?) -> [IFolder]?

    /**
     - Returns: The folder of the given type, if any.
     */
    func folderByType(_ type: FolderType, email: String) -> IFolder?

    /**
     - Returns: The folder of the given type, if any.
     */
    func folderByType(_ type: FolderType, account: IAccount) -> IFolder?

    func accountByEmail(_ email: String) -> IAccount?
    func accountsByPredicate(_ predicate: NSPredicate?,
                             sortDescriptors: [NSSortDescriptor]?) -> [IAccount]?
    func setAccountAsLastUsed(_ account: IAccount) -> IAccount
    func fetchLastAccount() -> IAccount?

    func insertAccountFromConnectInfo(_ connectInfo: ConnectInfo) -> IAccount
    func insertNewMessage() -> IMessage

    /**
     Creates new message for sending, with the correct from and folder setup.
     */
    func insertNewMessageForSendingFromAccountEmail(_ email: String) -> IMessage?

    func insertAttachmentWithContentType(
        _ contentType: String?, filename: String?, data: Data) -> IAttachment

    func insertOrUpdateContactEmail(_ email: String, name: String?) -> IContact
    func insertOrUpdateContactEmail(_ email: String) -> IContact
    func insertOrUpdateContact(_ contact: IContact) -> IContact

    /**
     Inserts a folder of the given type, creating the whole hierarchy if necessary.
     - Note: Caller is responsible for saving the model!
     - Parameter folderName: The name of the folder
     - Parameter folderSeparator: The folder separator, for determining hierarchy.
     If this is nil, the folder will be created as-is, with searching for a parent.
     If this is non-nil, the folder name will be interpreted as a path, and the
     result will be the creation of a hierarchical folder structure (if the folder
     is not a root folder).
     - Parameter accountEmail: The email of the account this folder belongs to.
     */
    func insertOrUpdateFolderName(_ folderName: String, folderSeparator: String?,
                                  accountEmail: String) -> IFolder?

    func insertOrUpdateMessageReference(_ messageID: String) -> IMessageReference
    func insertMessageReference(_ messageID: String) -> IMessageReference

    /**
     Quickly inserts essential parts of a pantomime into the store. Needed for networking,
     where inserts should be quick and the persistent store should be up-to-date
     nevertheless (especially in terms of UIDs, messageNumbers etc.)
     - Returns: A tuple of the optional message just created or updated, and a Bool
     for whether the mail already existed or has been freshly added (true for having been
     freshly added).
     */
    func quickInsertOrUpdatePantomimeMail(_ message: CWIMAPMessage, accountEmail: String)
        -> (IMessage?, Bool)

    /**
     Converts a pantomime mail to an IMessage and stores it.
     Don't use this on the main thread as there is potentially a lot of processing involved
     (e.g., parsing of HTML and/or attachments).
     - Parameter message: The pantomime message to insert.
     - Parameter accountEmail: The email for the account this email is supposed to be stored
     for.
     - Parameter forceParseAttachments: If true, this will parse the attachments even
     if the pantomime has not been initialized yet (useful for testing only).
     - Returns: The newly created or updated IMessage
     */
    func insertOrUpdatePantomimeMail(_ message: CWIMAPMessage, accountEmail: String,
                                     forceParseAttachments: Bool) -> IMessage?

    /**
     - Returns: List of contact that match the given snippet (either in the name, or email).
     */
    func contactsBySnippet(_ snippet: String) -> [IContact]

    func save()

    /**
     For debugging: Dumps some important DB contents.
     */
    func dumpDB()

    /**
     Deletes the given mail from the store.
     */
    func deleteMail(_ message: IMessage)

    /**
     Deletes the given attachment from the store.
     */
    func deleteAttachment(_ attachment: IAttachment)

    /**
     Deletes all attachments from the given mail.
     */
    func deleteAttachmentsFromMessage(_ message: IMessage)

    /**
     - Returns: A predicate for all viewable emails.
     */
    func basicMessagePredicate() -> NSPredicate

    /**
     - Returns: true if there are no accounts yet.
     */
    func accountsIsEmpty() -> Bool
}

/**
 Core data implementation
 */
open class Model: IModel {
    let comp = "Model"

    open static let CouldNotCreateFolder = 1000

    open let context: NSManagedObjectContext

    public init(context: NSManagedObjectContext) {
        self.context = context
    }

    func singleEntityWithName(_ name: String, predicate: NSPredicate? = nil,
                              sortDescriptors: [NSSortDescriptor]? = nil) -> NSManagedObject? {
        let fetch = NSFetchRequest.init(entityName: name)
        fetch.predicate = predicate
        fetch.sortDescriptors = sortDescriptors
        do {
            let objs = try context.fetch(fetch)
            if objs.count == 1 {
                return objs[0] as? NSManagedObject
            } else if objs.count == 0 {
                return nil
            } else {
                Log.warnComponent(comp, "Several objects (\(name)) found for predicate: \(predicate)")
                return objs[0] as? NSManagedObject
            }
        } catch let err as NSError {
            Log.errorComponent(comp, error: err)
        }
        return nil
    }

    open func entitiesWithName(
        _ name: String, predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor]? = nil)
        -> [NSManagedObject]?
    {
        let fetch = NSFetchRequest.init(entityName: name)
        fetch.predicate = predicate
        fetch.sortDescriptors = sortDescriptors
        do {
            let objs = try context.fetch(fetch)
            return objs as? [NSManagedObject]
        } catch let err as NSError {
            Log.errorComponent(comp, error: err)
        }
        return nil
    }

    open func countWithName(_ name: String,
                              predicate: NSPredicate? = nil) -> Int {
        let fetch = NSFetchRequest.init(entityName: name)
        fetch.predicate = predicate
        do {
            let number = try context.count(for: fetch)
            if number != NSNotFound {
                return number
            }
        } catch let error as NSError {
            Log.errorComponent(comp, error: error)
        }
        return 0
    }

    open func contactByEmail(_ email: String) -> IContact? {
        if let contacts = contactsByPredicate(NSPredicate.init(format: "email = %@", email), sortDescriptors: nil) {
            if contacts.count == 1 {
                return contacts[0]
            } else if contacts.count == 0 {
                return nil
            } else {
                Log.warnComponent(comp, "Several contacts found for email: \(email)")
                return contacts[0]
            }
        }
        return nil
    }

    open func contactsByPredicate(_ predicate: NSPredicate?,
                                    sortDescriptors: [NSSortDescriptor]?) -> [IContact]? {
        return entitiesWithName(Contact.entityName(), predicate: predicate,
            sortDescriptors: sortDescriptors)?.map() {$0 as! IContact}
    }

    open func existingMessage(_ msg: CWIMAPMessage) -> IMessage? {
        var predicates: [NSPredicate] = []
        if let msgId = msg.messageID() {
            predicates.append(NSPredicate.init(format: "messageID = %@", msgId))
        }
        if msg.folder() != nil {
            predicates.append(NSPredicate.init(format: "folder.name = %@", msg.folder()!.name()))
        }
        if msg.uid() > 0 {
            predicates.append(NSPredicate.init(format: "uid = %d", msg.uid()))
        }
        if msg.subject() != nil && msg.receivedDate() != nil {
            predicates.append(NSPredicate.init(format: "subject = %@ and receivedDate = %@",
                msg.subject()!, msg.receivedDate()! as CVarArg))
        }
        let pred = NSCompoundPredicate.init(andPredicateWithSubpredicates: predicates)
        if let mail = singleEntityWithName(Message.entityName(), predicate: pred) {
            let result = mail as! Message
            return result
        }
        return nil
    }

    func newAccountFromConnectInfo(_ connectInfo: ConnectInfo) -> IAccount {
        let account = NSEntityDescription.insertNewObject(
            forEntityName: Account.entityName(), into: context) as! Account
        account.nameOfTheUser = connectInfo.nameOfTheUser
        account.email = connectInfo.email
        account.imapUsername = connectInfo.imapUsername
        account.smtpUsername = connectInfo.smtpUsername
        account.imapServerName = connectInfo.imapServerName
        account.smtpServerName = connectInfo.smtpServerName
        account.imapServerPort = NSNumber.init(value: Int16(connectInfo.imapServerPort) as Int16)
        account.smtpServerPort = NSNumber.init(value: Int16(connectInfo.smtpServerPort) as Int16)
        account.imapTransport = NSNumber.init(value: Int16(connectInfo.imapTransport.rawValue) as Int16)
        account.smtpTransport = NSNumber.init(value: Int16(connectInfo.smtpTransport.rawValue) as Int16)

        return account
    }

    open func insertAccountFromConnectInfo(_ connectInfo: ConnectInfo) -> IAccount {
        if let ac = accountByEmail(connectInfo.email) {
            return ac
        }

        let account = newAccountFromConnectInfo(connectInfo)
        save()
        KeyChain.addEmail(connectInfo.email, serverType: Account.AccountType.imap.asString(),
                          password: connectInfo.imapPassword)
        KeyChain.addEmail(connectInfo.email, serverType: Account.AccountType.smtp.asString(),
                          password: connectInfo.getSmtpPassword())
        return account
    }

    open func insertNewMessage() -> IMessage {
        let mail = NSEntityDescription.insertNewObject(
            forEntityName: Message.entityName(), into: context) as! Message
        return mail
    }

    open func insertNewMessageForSendingFromAccountEmail(_ email: String) -> IMessage? {
        guard let account = accountByEmail(email) else {
            Log.warnComponent(comp, "No account with email found: \(email)")
            return nil
        }
        let message = insertNewMessage()
        let contact = insertOrUpdateContactEmail(account.email, name: account.nameOfTheUser)
        message.from = contact as? Contact
        guard let folder = folderByType(FolderType.localOutbox, email: account.email) else {
            Log.warnComponent(comp, "Expected outbox folder to exist")
            return nil
        }
        message.folder = folder as! Folder
        return message
    }

    open func insertAttachmentWithContentType(
        _ contentType: String?, filename: String?, data: Data) -> IAttachment {
        let attachment = NSEntityDescription.insertNewObject(
            forEntityName: Attachment.entityName(), into: context) as! Attachment
        attachment.contentType = contentType
        attachment.filename = filename
        attachment.size = NSNumber(data.count)
        attachment.data = data
        return attachment
    }

    open func setAccountAsLastUsed(_ account: IAccount) -> IAccount {
        UserDefaults.standard.set(
            account.email, forKey: Account.kSettingLastAccountEmail)
        UserDefaults.standard.synchronize()
        return account
    }

    open func fetchLastAccount() -> IAccount? {
        let lastEmail = UserDefaults.standard.string(
            forKey: Account.kSettingLastAccountEmail)

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

    open func accountsIsEmpty() -> Bool {
        if let acc = accountsByPredicate(NSPredicate.init(value: true)) {
            return acc.isEmpty
        }
        return false
    }

    open func accountByEmail(_ email: String) -> IAccount? {
        let predicate = NSPredicate.init(format: "email = %@", email)
        return singleEntityWithName(Account.entityName(), predicate: predicate)
            as? Account
    }

    open func accountsByPredicate(_ predicate: NSPredicate? = nil,
                                    sortDescriptors: [NSSortDescriptor]? = nil) -> [IAccount]? {
        return entitiesWithName(Account.entityName(), predicate: predicate,
            sortDescriptors: sortDescriptors)?.map() {$0 as! IAccount}
    }

    open func save() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                Log.errorComponent(CoreDataUtil.comp, error: nserror)
                abort()
            }
        }
    }

    func folderPredicateByName(_ name: String, email: String) -> NSPredicate {
        return NSPredicate.init(format: "account.email = %@ and name = %@", email, name)
    }

    func insertFolderName(_ name: String, account: IAccount) -> IFolder {
        if let folder = folderByName(name, email: account.email) {
            // reactivate folder if previously deleted
            folder.shouldDelete = false

            return folder
        }

        let folder = NSEntityDescription.insertNewObject(
            forEntityName: Folder.entityName(), into: context) as! Folder

        folder.name = name
        folder.account = account as! Account
        folder.shouldDelete = false

        // Default value
        folder.folderType = NSNumber.init(value: FolderType.normal.rawValue as Int)

        if name.uppercased() == ImapSync.defaultImapInboxName.uppercased() {
            folder.folderType = NSNumber.init(value: FolderType.inbox.rawValue as Int)
        } else {
            for ty in FolderType.allValuesToCheckFromServer {
                var foundMatch = false
                for theName in ty.folderNames() {
                    if name.matchesPattern("\(theName)",
                                           reOptions: [.caseInsensitive]) {
                        folder.folderType = NSNumber.init(value: ty.rawValue as Int)
                        foundMatch = true
                        break
                    }
                }
                if foundMatch {
                    break
                }
            }
        }

        return folder
    }

    func reactivateFolder(_ folder: IFolder) -> IFolder {
        folder.shouldDelete = false
        return folder
    }

    open func insertOrUpdateFolderName(_ folderName: String, folderSeparator: String?,
                                         accountEmail: String) -> IFolder? {
        // Treat Inbox specially, since its name is case insensitive.
        // For all other folders, it's undefined if they have to be handled
        // case insensitive or not, so no special handling for those.
        if folderName.lowercased() == ImapSync.defaultImapInboxName.lowercased() {
            if let folder = folderByType(.inbox, email: accountEmail) {
                return reactivateFolder(folder)
            }
        }
        if let folder = folderByName(folderName, email: accountEmail) {
            return reactivateFolder(folder)
        }

        if let account = accountByEmail(accountEmail) {
            if let separator = folderSeparator {
                account.folderSeparator = folderSeparator

                // Create folder hierarchy if necessary
                var pathsSoFar = [String]()
                var parentFolder: Folder? = nil
                let paths = folderName.components(separatedBy: separator)
                for p in paths {
                    pathsSoFar.append(p)
                    let pathName = (pathsSoFar as NSArray).componentsJoined(
                        by: separator)
                    let folder = insertFolderName(pathName, account: account)
                    folder.parent = parentFolder
                    if let pf = parentFolder {
                        pf.addChildrenObject(folder as! Folder)
                    }
                    parentFolder = folder as? Folder
                }
                return parentFolder
            } else {
                // Just create the folder as-is, can't check for hierarchy
                let folder = insertFolderName(folderName, account: account)
                return folder
            }

        }
        return nil
    }

    open func messageByPredicate(_ predicate: NSPredicate? = nil,
                                   sortDescriptors: [NSSortDescriptor]? = nil) -> IMessage? {
        return singleEntityWithName(Message.entityName(), predicate: predicate,
                                    sortDescriptors: sortDescriptors) as? Message
    }

    open func messagesByPredicate(_ predicate: NSPredicate? = nil,
                                    sortDescriptors: [NSSortDescriptor]? = nil) -> [IMessage]? {
        return entitiesWithName(Message.entityName(), predicate: predicate,
            sortDescriptors: sortDescriptors)?.map() {$0 as! Message}
    }

    open func messageCountByPredicate(_ predicate: NSPredicate? = nil) -> Int {
        return countWithName(Message.entityName(), predicate: predicate)
    }

    open func messageByUID(_ uid: Int, folderName: String) -> IMessage? {
        return messageByPredicate(NSPredicate.init(format: "uid = %d", uid))
    }

    open func messageByMessageID(_ messageID: String) -> IMessage? {
        let predicate = NSPredicate.init(format: "messageID = %@", messageID)
        return messageByPredicate(predicate, sortDescriptors: nil)
    }

    open func lastUidInFolderNamed(_ folderName: String) -> UInt {
        let fetch = NSFetchRequest.init(entityName: Message.entityName())
        fetch.predicate = NSPredicate.init(format: "folder.name = %@", folderName)
        fetch.fetchLimit = 1
        fetch.sortDescriptors = [NSSortDescriptor.init(key: "uid", ascending: false)]
        do {
            let elems = try context.fetch(fetch)
            if elems.count > 0 {
                if elems.count > 1 {
                    Log.warnComponent(comp, "lastUID has found more than one element")
                }
                if let msg = elems[0] as? Message {
                    return UInt(msg.uid.intValue)
                } else {
                    Log.warnComponent(comp, "Could not cast core data result to Message")
                }
            } else if elems.count > 0 {
                Log.warnComponent(comp, "lastUID has several objects with the same UID?")
            }
        } catch let error as NSError {
            Log.errorComponent(comp, error: error)
        }
        Log.warnComponent(comp, "lastUID no object found, returning 0")
        return 0
    }

    open func folderCountByPredicate(_ predicate: NSPredicate? = nil) -> Int {
        return countWithName(Folder.entityName(), predicate: predicate)
    }

    open func foldersByPredicate(_ predicate: NSPredicate? = nil,
                                   sortDescriptors: [NSSortDescriptor]? = nil) -> [IFolder]? {
        return entitiesWithName(Folder.entityName(), predicate: predicate,
            sortDescriptors: sortDescriptors)?.map() {$0 as! Folder}
    }

    open func folderByPredicate(_ predicate: NSPredicate? = nil,
                                  sortDescriptors: [NSSortDescriptor]? = nil) -> IFolder? {
        return singleEntityWithName(Folder.entityName(), predicate: predicate,
                                    sortDescriptors: sortDescriptors) as? Folder
    }

    open func folderByName(_ name: String, email: String) -> IFolder? {
        return folderByPredicate(folderPredicateByName(name, email: email))
    }

    open func folderByName(
        _ name: String, email: String, folderType: Account.AccountType) -> IFolder? {
        let p1 = folderPredicateByName(name, email: email)
        let p2 = NSPredicate.init(format: "folderType = %d", folderType.rawValue)
        let p3 = NSPredicate.init(format: "shouldDelete == false")
        let p = NSCompoundPredicate.init(andPredicateWithSubpredicates: [p1, p2, p3])
        return folderByPredicate(p)
    }

    open func anyFolderByName(_ name: String, email: String) -> IFolder? {
        let p1 = folderPredicateByName(name, email: email)
        return folderByPredicate(p1)
    }

    open func foldersForAccountEmail(_ accountEmail: String, predicate: NSPredicate?,
                                       sortDescriptors: [NSSortDescriptor]?) -> [IFolder]? {
        var p1 = NSPredicate.init(format: "account.email = %@", accountEmail)
        if let p2 = predicate {
            p1 = NSCompoundPredicate.init(andPredicateWithSubpredicates: [p1, p2])
        }
        return foldersByPredicate(p1, sortDescriptors: sortDescriptors)
    }

    /**
     Somewhat fuzzy predicate for getting a folder.
     */
    func folderFuzzyPredicateByName(_ folderName: String) -> NSPredicate {
        let p = NSPredicate.init(format: "name contains[c] %@", folderName)
        return p
    }

    open func folderByType(_ type: FolderType, email: String) -> IFolder? {
        let p1 = NSPredicate.init(format: "account.email == %@", email)
        let p2 = NSPredicate.init(format: "folderType == %d", type.rawValue)
        let p3 = NSPredicate.init(format: "shouldDelete == false")
        let p = NSCompoundPredicate.init(andPredicateWithSubpredicates: [p1, p2, p3])
        return singleEntityWithName(Folder.entityName(), predicate: p) as? IFolder
    }

    open func folderByType(_ type: FolderType, account: IAccount) -> IFolder? {
        return folderByType(type, email: account.email)
    }

    open func insertOrUpdateContactEmail(_ email: String, name: String?) -> IContact {
        let fetch = NSFetchRequest.init(entityName:Contact.entityName())
        fetch.predicate = NSPredicate.init(format: "email == %@", email)
        do {
            var existing = try context.fetch(fetch) as! [Contact]
            if existing.count > 1 {
                Log.warnComponent(comp, "Duplicate contacts with address \(email)")
                existing[0].updateName(name)
                return existing[0]
            } else if existing.count == 1 {
                existing[0].updateName(name)
                return existing[0]
            }
        } catch let err as NSError {
            Log.errorComponent(comp, error: err)
        }
        let contact = NSEntityDescription.insertNewObject(
            forEntityName: Contact.entityName(), into: context) as! Contact
        contact.email = email
        contact.name = name
        return contact
    }

    open func insertOrUpdateContactEmail(_ email: String) -> IContact {
        return insertOrUpdateContactEmail(email, name: nil)
    }

    open func insertOrUpdateContact(_ contact: IContact) -> IContact {
        let c = self.insertOrUpdateContactEmail(
            contact.email, name: contact.name)
        if let abID = contact.addressBookID {
            c.addressBookID = abID
        }
        if let pepUserID = contact.pepUserID {
            c.pepUserID = pepUserID
        }
        return c
    }

    open func insertOrUpdateMessageReference(_ messageID: String) -> IMessageReference {
        let p = NSPredicate.init(format: "messageID = %@", messageID)
        if let ent = singleEntityWithName(MessageReference.entityName(), predicate: p) {
            return ent as! MessageReference
        } else {
            return insertMessageReference(messageID)
        }
    }

    open func insertMessageReference(_ messageID: String) -> IMessageReference {
        let ref = NSEntityDescription.insertNewObject(
            forEntityName: MessageReference.entityName(), into: context) as! MessageReference
        ref.messageID = messageID
        if let msg = messageByMessageID(messageID) {
            ref.message = msg as? Message
        }
        return ref
    }

    open func addContacts(_ contacts: [CWInternetAddress]) -> [String: IContact] {
        var added: [String: IContact] = [:]
        for address in contacts {
            let addr = insertOrUpdateContactEmail(address.address(),
                                                  name: address.personal())
            added[addr.email] = addr
        }
        return added
    }

    /**
     Inserts or updates a pantomime message into the data store with only the bare minimum
     of data.
     - Returns: A tuple consisting of the message inserted and a Bool denoting
     whether this message was just inserted (true)
     or an existing message was found (false).
     */
    open func quickInsertOrUpdatePantomimeMail(_ message: CWIMAPMessage,
                                                 accountEmail: String) -> (IMessage?, Bool) {
        guard let folderName = message.folder()?.name() else {
            return (nil, false)
        }
        guard let folder = folderByName(folderName, email: accountEmail) else {
            return (nil, false)
        }

        var theMail: IMessage? = existingMessage(message)
        if theMail == nil {
            theMail = insertNewMessage()
        }

        let mail = theMail!

        mail.folder = folder as! Folder
        mail.bodyFetched = message.isInitialized() as NSNumber
        mail.receivedDate = message.receivedDate()
        mail.subject = message.subject()
        mail.messageID = message.messageID()
        mail.uid = NSNumber(message.uid())
        mail.messageNumber = message.messageNumber() as NSNumber?
        mail.boundary = (message.boundary() as NSData?)?.asciiString()

        // sync flags
        let flags = message.flags()
        mail.flagsFromServer = NSNumber.init(value: flags.rawFlagsAsShort() as Int16)
        mail.flags = mail.flagsFromServer
        mail.flagSeen = flags.contain(.seen) as NSNumber
        mail.flagAnswered = flags.contain(.answered) as NSNumber
        mail.flagFlagged = flags.contain(.flagged) as NSNumber
        mail.flagDeleted = flags.contain(.deleted) as NSNumber
        mail.flagDraft = flags.contain(.draft) as NSNumber
        mail.flagRecent = flags.contain(.recent) as NSNumber

        return (mail, false)
    }

    open func insertOrUpdatePantomimeMail(
        _ message: CWIMAPMessage, accountEmail: String,
        forceParseAttachments: Bool = false) -> IMessage? {
        let (quickMail, isFresh) = quickInsertOrUpdatePantomimeMail(message,
                                                                    accountEmail: accountEmail)
        guard let mail = quickMail else {
            return nil
        }

        if let from = message.from() {
            let contactsFrom = addContacts([from])
            let email = from.address()
            let c = contactsFrom[email!]
            mail.from = c as? Contact
        }

        mail.bodyFetched = message.isInitialized() as NSNumber

        let addresses = message.recipients() as! [CWInternetAddress]
        let contacts = addContacts(addresses)

        let tos: NSMutableOrderedSet = []
        let ccs: NSMutableOrderedSet = []
        let bccs: NSMutableOrderedSet = []
        for addr in addresses {
            switch addr.type() {
            case .toRecipient:
                tos.add(contacts[addr.address()]! as! Contact)
            case .ccRecipient:
                ccs.add(contacts[addr.address()]! as! Contact)
            case .bccRecipient:
                bccs.add(contacts[addr.address()]! as! Contact)
            default:
                Log.warnComponent(comp, "Unsupported recipient type \(addr.type()) for \(addr.address())")
            }
        }
        if isFresh || mail.to != tos {
            mail.to = tos
        }
        if isFresh || mail.cc != ccs {
            mail.cc = ccs
        }
        if isFresh || mail.bcc != bccs {
            mail.bcc = bccs
        }

        let referenceStrings = NSMutableOrderedSet()
        if let pantomimeRefs = message.allReferences() {
            for ref in pantomimeRefs {
                referenceStrings.add(ref)
            }
        }
        // Append inReplyTo to references (https://cr.yp.to/immhf/thread.html)
        if let inReplyTo = message.inReplyTo() {
            referenceStrings.add(inReplyTo)
        }

        for refID in referenceStrings {
            let ref = insertOrUpdateMessageReference(refID as! String)
            (mail as! Message).addReferencesObject(ref as! MessageReference)
        }

        mail.contentType = message.contentType()

        if forceParseAttachments || mail.bodyFetched.intValue == 1 {
            // Parsing attachments only makes sense once pantomime has received the
            // mail body. Same goes for the snippet.
            addAttachmentsFromPantomimePart(message, targetMail: mail as! Message, level: 0)
        }

        return mail
    }

    func addAttachmentsFromPantomimePart(_ part: CWPart, targetMail: Message, level: Int) {
        guard let content = part.content() else {
            return
        }

        let isText = part.contentType()?.lowercased() == Constants.contentTypeText
        let isHtml = part.contentType()?.lowercased() == Constants.contentTypeHtml
        var contentData: Data?
        if let message = content as? CWMessage {
            contentData = message.dataValue()
        } else if let string = content as? NSString {
            contentData = string.data(using: String.Encoding.ascii.rawValue)
        } else if let data = content as? Data {
            contentData = data
        }
        if let data = contentData {
            if isText && level < 3 && targetMail.longMessage == nil &&
                MiscUtil.isEmptyString(part.filename()) {
                targetMail.longMessage = data.toStringWithIANACharset(part.charset())
            } else if isHtml && level < 3 && targetMail.longMessageFormatted == nil &&
                MiscUtil.isEmptyString(part.filename()) {
                targetMail.longMessageFormatted = data.toStringWithIANACharset(part.charset())
            } else {
                let attachment = insertAttachmentWithContentType(
                    part.contentType(), filename: part.filename(), data: data)
                targetMail.addAttachmentsObject(attachment as! Attachment)
            }
        }

        if let multiPart = content as? CWMIMEMultipart {
            for i in 0..<multiPart.count() {
                let subPart = multiPart.part(at: UInt(i))
                addAttachmentsFromPantomimePart(subPart!, targetMail: targetMail, level: level + 1)
            }
        }
    }

    open func contactsBySnippet(_ snippet: String) -> [IContact] {
        let p = NSPredicate.init(format: "email != nil and email != \"\" and " +
            "(email contains[cd] %@ or name contains[cd] %@)",
                                 snippet, snippet)
        if let contacts = contactsByPredicate(
            p, sortDescriptors: [NSSortDescriptor.init(key: "name", ascending: true),
                NSSortDescriptor.init(key: "email", ascending: true)]) {
            return contacts
        }
        return []
    }

    open func dumpDB() {
        if let folders = foldersByPredicate(NSPredicate.init(value: true)) {
            for folder in folders {
                Log.infoComponent(
                    comp,
                    "Folder \(folder.name) \(folder.messages.count) messages accountType \(folder.account.accountType)")
            }
        }

        if let messages = messagesByPredicate(NSPredicate.init(value: true)) {
            for msg in messages {
                Log.infoComponent(
                    comp,
                    "Message \(msg.uid) folder \(msg.folder.name) folder.count \(msg.folder.messages.count) accountType \(msg.folder.account.accountType)")
            }
        }
    }

    open func deleteMail(_ message: IMessage) {
        if let msg = message as? Message {
            context.delete(msg)
        }
    }

    open func deleteAttachment(_ attachment: IAttachment) {
        if let a = attachment as? Attachment {
            context.delete(a)
        }
    }

    open func deleteAttachmentsFromMessage(_ message: IMessage) {
        if let msg = message as? Message {
            for a in msg.attachments {
                context.delete(a as! Attachment)
            }
            message.attachments = NSOrderedSet()
        } else {
            message.attachments = NSOrderedSet()
        }
    }

    open func basicMessagePredicate() -> NSPredicate {
        let predicateDecrypted = NSPredicate.init(format: "pepColorRating != nil")
        let predicateBody = NSPredicate.init(format: "bodyFetched = true")
        let predicateNotDeleted = NSPredicate.init(format: "flagDeleted = false")
        let predicates: [NSPredicate] = [predicateBody, predicateDecrypted,
                                         predicateNotDeleted]
        let predicate = NSCompoundPredicate.init(
            andPredicateWithSubpredicates: predicates)
        return predicate
    }
}
