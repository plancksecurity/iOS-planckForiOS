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
    var context: NSManagedObjectContext { get }

    /**
     Retrieve a contact by email, without updating anything.
     */
    func contactByEmail(email: String) -> IContact?

    func contactsByPredicate(predicate: NSPredicate?,
                             sortDescriptors: [NSSortDescriptor]?) -> [IContact]?

    func existingMessage(msg: CWIMAPMessage) -> IMessage?
    func messageByPredicate(predicate: NSPredicate?,
                            sortDescriptors: [NSSortDescriptor]?) -> IMessage?
    func messagesByPredicate(predicate: NSPredicate?,
                             sortDescriptors: [NSSortDescriptor]?) -> [IMessage]?
    func messageCountByPredicate(predicate: NSPredicate?) -> Int

    /**
     -Returns: The highest UID of the messages in the given folder.
     */
    func lastUidInFolderNamed(folderName: String) -> UInt

    func folderCountByPredicate(predicate: NSPredicate?) -> Int
    func foldersByPredicate(predicate: NSPredicate?,
                            sortDescriptors: [NSSortDescriptor]?) -> [IFolder]?
    func folderByPredicate(predicate: NSPredicate?,
                           sortDescriptors: [NSSortDescriptor]?) -> IFolder?
    func folderByName(name: String, email: String) -> IFolder?
    func folderByName(name: String, email: String, folderType: Account.AccountType) -> IFolder?
    func foldersForAccountEmail(accountEmail: String, predicate: NSPredicate?,
                                sortDescriptors: [NSSortDescriptor]?) -> [IFolder]?

    /**
     - Returns: The folder of the given type, if any.
     */
    func folderByType(type: FolderType, email: String) -> IFolder?

    func accountByEmail(email: String) -> IAccount?
    func accountsByPredicate(predicate: NSPredicate?,
                             sortDescriptors: [NSSortDescriptor]?) -> [IAccount]?
    func setAccountAsLastUsed(account: IAccount) -> IAccount
    func fetchLastAccount() -> IAccount?

    func insertAccountFromConnectInfo(connectInfo: ConnectInfo) -> IAccount
    func insertNewMessage() -> IMessage

    /**
     Creates new message for sending, with the correct from and folder setup.
     */
    func insertNewMessageForSendingFromAccountEmail(email: String) -> IMessage?

    func insertAttachmentWithContentType(
        contentType: String?, filename: String?, data: NSData) -> IAttachment

    func insertOrUpdateContactEmail(email: String, name: String?) -> IContact
    func insertOrUpdateContactEmail(email: String) -> IContact
    func insertOrUpdateContact(contact: IContact) -> IContact

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
    func insertOrUpdateFolderName(folderName: String, folderSeparator: String?,
                                  accountEmail: String) -> IFolder?

    func insertOrUpdateMessageReference(messageID: String) -> IMessageReference
    func insertMessageReference(messageID: String) -> IMessageReference

    /**
     Quickly inserts essential parts of a pantomime into the store. Needed for networking,
     where inserts should be quick and the persistent store should be up-to-date
     nevertheless (especially in terms of UIDs, messageNumbers etc.)
     - Returns: A tuple of the optional message just created or updated, and a Bool
     for whether the mail already existed or has been freshly added (true for having been
     freshly added).
     */
    func quickInsertOrUpdatePantomimeMail(message: CWIMAPMessage, accountEmail: String)
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
    func insertOrUpdatePantomimeMail(message: CWIMAPMessage, accountEmail: String,
                                     forceParseAttachments: Bool) -> IMessage?

    /**
     - Returns: List of contact that match the given snippet (either in the name, or email).
     */
    func contactsBySnippet(snippet: String) -> [IContact]

    func save()

    /**
     For debugging: Dumps some important DB contents.
     */
    func dumpDB()

    /**
     Deletes the given mail from the store.
     */
    func deleteMail(message: IMessage)

    /**
     Deletes the given attachment from the store.
     */
    func deleteAttachment(attachment: IAttachment)

    /**
     Deletes all attachments from the given mail.
     */
    func deleteAttachmentsFromMessage(message: IMessage)

    /**
     - Returns: A predicate for all viewable emails.
     */
    func basicMessagePredicate() -> NSPredicate
}

/**
 Core data implementation
 */
public class Model: IModel {
    let comp = "Model"

    public static let CouldNotCreateFolder = 1000

    public let context: NSManagedObjectContext

    public init(context: NSManagedObjectContext) {
        self.context = context
    }

    func singleEntityWithName(name: String, predicate: NSPredicate? = nil,
                              sortDescriptors: [NSSortDescriptor]? = nil) -> NSManagedObject? {
        let fetch = NSFetchRequest.init(entityName: name)
        fetch.predicate = predicate
        fetch.sortDescriptors = sortDescriptors
        do {
            let objs = try context.executeFetchRequest(fetch)
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

    public func entitiesWithName(
        name: String, predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor]? = nil)
        -> [NSManagedObject]?
    {
        let fetch = NSFetchRequest.init(entityName: name)
        fetch.predicate = predicate
        fetch.sortDescriptors = sortDescriptors
        do {
            let objs = try context.executeFetchRequest(fetch)
            return objs as? [NSManagedObject]
        } catch let err as NSError {
            Log.errorComponent(comp, error: err)
        }
        return nil
    }

    public func countWithName(name: String,
                              predicate: NSPredicate? = nil) -> Int {
        let fetch = NSFetchRequest.init(entityName: name)
        fetch.predicate = predicate
        var error: NSError?
        let number = context.countForFetchRequest(fetch, error: &error)
        if let err = error {
            Log.errorComponent(comp, error: err)
        }
        if number != NSNotFound {
            return number
        }
        return 0
    }

    public func contactByEmail(email: String) -> IContact? {
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

    public func contactsByPredicate(predicate: NSPredicate?,
                                    sortDescriptors: [NSSortDescriptor]?) -> [IContact]? {
        return entitiesWithName(Contact.entityName(), predicate: predicate,
            sortDescriptors: sortDescriptors)?.map() {$0 as! IContact}
    }

    public func existingMessage(msg: CWIMAPMessage) -> IMessage? {
        var predicates: [NSPredicate] = []
        if let msgId = msg.messageID() {
            predicates.append(NSPredicate.init(format: "messageID = %@", msgId))
        }
        if msg.folder() != nil {
            predicates.append(NSPredicate.init(format: "folder.name = %@", msg.folder()!.name()))
        }
        if msg.UID() > 0 {
            predicates.append(NSPredicate.init(format: "uid = %d", msg.UID()))
        }
        if msg.subject() != nil && msg.receivedDate() != nil {
            predicates.append(NSPredicate.init(format: "subject = %@ and receivedDate = %@",
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
        account.nameOfTheUser = connectInfo.nameOfTheUser
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

    public func insertAccountFromConnectInfo(connectInfo: ConnectInfo) -> IAccount {
        if let ac = accountByEmail(connectInfo.email) {
            return ac
        }

        let account = newAccountFromConnectInfo(connectInfo)
        save()
        KeyChain.addEmail(connectInfo.email, serverType: Account.AccountType.IMAP.asString(),
                          password: connectInfo.imapPassword)
        KeyChain.addEmail(connectInfo.email, serverType: Account.AccountType.SMTP.asString(),
                          password: connectInfo.getSmtpPassword())
        return account
    }

    public func insertNewMessage() -> IMessage {
        let mail = NSEntityDescription.insertNewObjectForEntityForName(
            Message.entityName(), inManagedObjectContext: context) as! Message
        return mail
    }

    public func insertNewMessageForSendingFromAccountEmail(email: String) -> IMessage? {
        guard let account = accountByEmail(email) else {
            Log.warnComponent(comp, "No account with email found: \(email)")
            return nil
        }
        let message = insertNewMessage()
        let contact = insertOrUpdateContactEmail(account.email, name: account.nameOfTheUser)
        message.from = contact as? Contact
        guard let folder = folderByType(FolderType.LocalOutbox, email: account.email) else {
            Log.warnComponent(comp, "Expected outbox folder to exist")
            return nil
        }
        message.folder = folder as! Folder
        return message
    }

    public func insertAttachmentWithContentType(
        contentType: String?, filename: String?, data: NSData) -> IAttachment {
        let attachment = NSEntityDescription.insertNewObjectForEntityForName(
            Attachment.entityName(), inManagedObjectContext: context) as! Attachment
        attachment.contentType = contentType
        attachment.filename = filename
        attachment.size = data.length
        attachment.data = data
        return attachment
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

    public func accountsByPredicate(predicate: NSPredicate? = nil,
                                    sortDescriptors: [NSSortDescriptor]? = nil) -> [IAccount]? {
        return entitiesWithName(Account.entityName(), predicate: predicate,
            sortDescriptors: sortDescriptors)?.map() {$0 as! IAccount}
    }

    public func save() {
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

    func folderPredicateByName(name: String, email: String) -> NSPredicate {
        return NSPredicate.init(format: "account.email = %@ and name = %@", email, name)
    }

    func insertFolderName(name: String, account: IAccount) -> IFolder {
        if let folder = folderByName(name, email: account.email) {
            return folder
        }

        let folder = NSEntityDescription.insertNewObjectForEntityForName(
            Folder.entityName(), inManagedObjectContext: context) as! Folder

        folder.name = name
        folder.account = account as! Account

        // Default value
        folder.folderType = NSNumber.init(integer: FolderType.Normal.rawValue)

        if name.uppercaseString == ImapSync.defaultImapInboxName.uppercaseString {
            folder.folderType = NSNumber.init(integer: FolderType.Inbox.rawValue)
        } else {
            for ty in FolderType.allValuesToCheckFromServer {
                var foundMatch = false
                for theName in ty.folderNames() {
                    if name.matchesPattern("\(theName)",
                                           reOptions: [.CaseInsensitive]) {
                        folder.folderType = NSNumber.init(integer: ty.rawValue)
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

    public func insertOrUpdateFolderName(folderName: String, folderSeparator: String?,
                                         accountEmail: String) -> IFolder? {
        if let folder = folderByName(folderName, email: accountEmail) {
            return folder
        }

        if let account = accountByEmail(accountEmail) {
            if let separator = folderSeparator {
                account.folderSeparator = folderSeparator

                // Create folder hierarchy if necessary
                var pathsSoFar = [String]()
                var parentFolder: Folder? = nil
                let paths = folderName.componentsSeparatedByString(separator)
                for p in paths {
                    pathsSoFar.append(p)
                    let pathName = (pathsSoFar as NSArray).componentsJoinedByString(
                        separator)
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

    public func messageByPredicate(predicate: NSPredicate? = nil,
                                   sortDescriptors: [NSSortDescriptor]? = nil) -> IMessage? {
        return singleEntityWithName(Message.entityName(), predicate: predicate,
                                    sortDescriptors: sortDescriptors) as? Message
    }

    public func messagesByPredicate(predicate: NSPredicate? = nil,
                                    sortDescriptors: [NSSortDescriptor]? = nil) -> [IMessage]? {
        return entitiesWithName(Message.entityName(), predicate: predicate,
            sortDescriptors: sortDescriptors)?.map() {$0 as! Message}
    }

    public func messageCountByPredicate(predicate: NSPredicate? = nil) -> Int {
        return countWithName(Message.entityName(), predicate: predicate)
    }

    public func messageByMessageID(messageID: String) -> IMessage? {
        let predicate = NSPredicate.init(format: "messageID = %@", messageID)
        return messageByPredicate(predicate, sortDescriptors: nil)
    }

    public func lastUidInFolderNamed(folderName: String) -> UInt {
        let fetch = NSFetchRequest.init(entityName: Message.entityName())
        fetch.predicate = NSPredicate.init(format: "folder.name = %@", folderName)
        fetch.fetchLimit = 1
        fetch.sortDescriptors = [NSSortDescriptor.init(key: "uid", ascending: false)]
        do {
            let elems = try context.executeFetchRequest(fetch)
            if elems.count > 0 {
                if elems.count > 1 {
                    Log.warnComponent(comp, "lastUID has found more than one element")
                }
                if let msg = elems[0] as? Message {
                    return UInt(msg.uid!.integerValue)
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

    public func folderCountByPredicate(predicate: NSPredicate? = nil) -> Int {
        return countWithName(Folder.entityName(), predicate: predicate)
    }

    public func foldersByPredicate(predicate: NSPredicate? = nil,
                                   sortDescriptors: [NSSortDescriptor]? = nil) -> [IFolder]? {
        return entitiesWithName(Folder.entityName(), predicate: predicate,
            sortDescriptors: sortDescriptors)?.map() {$0 as! Folder}
    }

    public func folderByPredicate(predicate: NSPredicate? = nil,
                                  sortDescriptors: [NSSortDescriptor]? = nil) -> IFolder? {
        return singleEntityWithName(Folder.entityName(), predicate: predicate,
                                    sortDescriptors: sortDescriptors) as? Folder
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

    public func foldersForAccountEmail(accountEmail: String, predicate: NSPredicate?,
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
    func folderFuzzyPredicateByName(folderName: String) -> NSPredicate {
        let p = NSPredicate.init(format: "name contains[c] %@", folderName)
        return p
    }

    public func folderByType(type: FolderType, email: String) -> IFolder? {
        let p1 = NSPredicate.init(format: "account.email == %@", email)
        let p2 = NSPredicate.init(format: "folderType == %d", type.rawValue)
        let p = NSCompoundPredicate.init(andPredicateWithSubpredicates: [p1, p2])
        return singleEntityWithName(Folder.entityName(), predicate: p) as? IFolder
    }

    public func insertOrUpdateContactEmail(email: String, name: String?) -> IContact {
        let fetch = NSFetchRequest.init(entityName:Contact.entityName())
        fetch.predicate = NSPredicate.init(format: "email == %@", email)
        do {
            var existing = try context.executeFetchRequest(fetch) as! [Contact]
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
        let contact = NSEntityDescription.insertNewObjectForEntityForName(
            Contact.entityName(), inManagedObjectContext: context) as! Contact
        contact.email = email
        contact.name = name
        return contact
    }

    public func insertOrUpdateContactEmail(email: String) -> IContact {
        return insertOrUpdateContactEmail(email, name: nil)
    }

    public func insertOrUpdateContact(contact: IContact) -> IContact {
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

    public func insertOrUpdateMessageReference(messageID: String) -> IMessageReference {
        let p = NSPredicate.init(format: "messageID = %@", messageID)
        if let ent = singleEntityWithName(MessageReference.entityName(), predicate: p) {
            return ent as! MessageReference
        } else {
            return insertMessageReference(messageID)
        }
    }

    public func insertMessageReference(messageID: String) -> IMessageReference {
        let ref = NSEntityDescription.insertNewObjectForEntityForName(
            MessageReference.entityName(), inManagedObjectContext: context) as! MessageReference
        ref.messageID = messageID
        if let msg = messageByMessageID(messageID) {
            ref.message = msg as? Message
        }
        return ref
    }

    public func addContacts(contacts: [CWInternetAddress]) -> [String: IContact] {
        var added: [String: IContact] = [:]
        for address in contacts {
            let addr = insertOrUpdateContactEmail(address.address(),
                                                  name: address.personal())
            added[addr.email] = addr
        }
        return added
    }

    /**
     Inserts or updates a pantomime message into the data store with only the bare minimum of data.
     - Returns: A tuple consisting of the message inserted and a Bool denoting whether this
     message was just inserted (true) or an existing message was found (false).
     */
    public func quickInsertOrUpdatePantomimeMail(message: CWIMAPMessage,
                                                 accountEmail: String) -> (IMessage?, Bool) {
        guard let folderName = message.folder()?.name() else {
            return (nil, false)
        }
        guard let folder = folderByName(folderName, email: accountEmail) else {
            return (nil, false)
        }

        var isFresh = false
        var theMail: IMessage? = existingMessage(message)
        if theMail == nil {
            theMail = insertNewMessage()
            isFresh = true
        }

        let mail = theMail!

        mail.folder = folder as! Folder

        mail.bodyFetched = message.isInitialized()

        if isFresh || mail.receivedDate != message.receivedDate() {
            mail.receivedDate = message.receivedDate()
        }
        if isFresh || mail.subject != message.subject() {
            mail.subject = message.subject()
        }
        if isFresh || mail.messageID != message.messageID() {
            mail.messageID = message.messageID()
        }
        if isFresh || mail.uid != message.UID() {
            mail.uid = message.UID()
        }
        if isFresh || mail.messageNumber != message.messageNumber() {
            mail.messageNumber = message.messageNumber()
        }
        if isFresh || mail.boundary != message.boundary()?.asciiString() {
            mail.boundary = message.boundary()?.asciiString()
        }
        return (mail, false)
    }

    public func insertOrUpdatePantomimeMail(
        message: CWIMAPMessage, accountEmail: String,
        forceParseAttachments: Bool = false) -> IMessage? {
        let (quickMail, isFresh) = quickInsertOrUpdatePantomimeMail(message,
                                                                    accountEmail: accountEmail)
        guard let mail = quickMail else {
            return nil
        }

        if let from = message.from() {
            let contactsFrom = addContacts([from])
            let email = from.address()
            let c = contactsFrom[email]
            mail.from = c as? Contact
        }

        mail.bodyFetched = message.isInitialized()

        let addresses = message.recipients() as! [CWInternetAddress]
        let contacts = addContacts(addresses)

        let tos: NSMutableOrderedSet = []
        let ccs: NSMutableOrderedSet = []
        let bccs: NSMutableOrderedSet = []
        for addr in addresses {
            switch addr.type() {
            case .ToRecipient:
                tos.addObject(contacts[addr.address()]! as! Contact)
            case .CcRecipient:
                ccs.addObject(contacts[addr.address()]! as! Contact)
            case .BccRecipient:
                bccs.addObject(contacts[addr.address()]! as! Contact)
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
                referenceStrings.addObject(ref)
            }
        }
        // Append inReplyTo to references (https://cr.yp.to/immhf/thread.html)
        if let inReplyTo = message.inReplyTo() {
            referenceStrings.addObject(inReplyTo)
        }

        for refID in referenceStrings {
            let ref = insertOrUpdateMessageReference(refID as! String)
            (mail as! Message).addReferencesObject(ref as! MessageReference)
        }

        mail.contentType = message.contentType()

        if forceParseAttachments || mail.bodyFetched.integerValue == 1 {
            // Parsing attachments only makes sense once pantomime has received the
            // mail body. Same goes for the snippet.
            addAttachmentsFromPantomimePart(message, targetMail: mail as! Message, level: 0)
        }

        return mail
    }

    func addAttachmentsFromPantomimePart(part: CWPart, targetMail: Message, level: Int) {
        guard let content = part.content() else {
            return
        }

        let isText = part.contentType()?.lowercaseString == Constants.contentTypeText
        let isHtml = part.contentType()?.lowercaseString == Constants.contentTypeHtml
        var contentData: NSData?
        if let message = content as? CWMessage {
            contentData = message.dataValue()
        } else if let string = content as? NSString {
            contentData = string.dataUsingEncoding(NSASCIIStringEncoding)
        } else if let data = content as? NSData {
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
                let subPart = multiPart.partAtIndex(UInt(i))
                addAttachmentsFromPantomimePart(subPart, targetMail: targetMail, level: level + 1)
            }
        }
    }

    public func contactsBySnippet(snippet: String) -> [IContact] {
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

    public func dumpDB() {
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

    public func deleteMail(message: IMessage) {
        if let msg = message as? Message {
            context.deleteObject(msg)
        }
    }

    public func deleteAttachment(attachment: IAttachment) {
        if let a = attachment as? Attachment {
            context.deleteObject(a)
        }
    }

    public func deleteAttachmentsFromMessage(message: IMessage) {
        if let msg = message as? Message {
            for a in msg.attachments {
                context.deleteObject(a as! Attachment)
            }
            message.attachments = NSOrderedSet()
        } else {
            message.attachments = NSOrderedSet()
        }
    }

    public func basicMessagePredicate() -> NSPredicate {
        let predicateBody = NSPredicate.init(format: "bodyFetched = true")
        let predicateDecrypted = NSPredicate.init(format: "pepColorRating != nil")
        let predicates: [NSPredicate] = [predicateBody, predicateDecrypted]
        let predicate = NSCompoundPredicate.init(
            andPredicateWithSubpredicates: predicates)
        return predicate
    }
}