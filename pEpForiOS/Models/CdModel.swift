//
//  CdModel.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 02/05/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import CoreData

import MessageModel

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


public protocol ICdModel {
    var context: NSManagedObjectContext { get }

    /**
     Retrieve a contact by email, without updating anything.
     */
    func contactByEmail(_ email: String) -> CdIdentity?

    func contactsByPredicate(_ predicate: NSPredicate?,
                             sortDescriptors: [NSSortDescriptor]?) -> [CdIdentity]?

    func existingMessage(_ msg: CWIMAPMessage) -> CdMessage?
    func messageByPredicate(_ predicate: NSPredicate?,
                            sortDescriptors: [NSSortDescriptor]?) -> CdMessage?
    func messagesByPredicate(_ predicate: NSPredicate?,
                             sortDescriptors: [NSSortDescriptor]?) -> [CdMessage]?
    func messageCountByPredicate(_ predicate: NSPredicate?) -> Int

    /**
     - Returns: A message with the given UID and folder name, if found.
     */
    func messageByUID(_ uid: Int, folderName: String) -> CdMessage?

    /**
     - Returns: The highest UID of the messages in the given folder.
     */
    func lastUidInFolderNamed(_ folderName: String) -> UInt

    func folderCountByPredicate(_ predicate: NSPredicate?) -> Int
    func foldersByPredicate(_ predicate: NSPredicate?,
                            sortDescriptors: [NSSortDescriptor]?) -> [CdFolder]?
    func folderByPredicate(_ predicate: NSPredicate?,
                           sortDescriptors: [NSSortDescriptor]?) -> CdFolder?

    /**
     Fetch a folder by name and account email.
     Will not return folders that are scheduled for deletion (where `shouldDelete` is true).
     */
    func folderByName(_ name: String, email: String) -> CdFolder?

    /**
     Fetch a folder by name and account email, and type.
     Will not return folders that are scheduled for deletion (where `shouldDelete` is true).
     */
    func folderByName(_ name: String, email: String, folderType: Server.ServerType) -> CdFolder?

    /**
     Fetch a folder by name and account email, even those scheduled for deletion
     (where `shouldDelete` is true).
     */
    func anyFolderByName(_ name: String, email: String) -> CdFolder?

    func foldersForAccountEmail(_ accountEmail: String, predicate: NSPredicate?,
                                sortDescriptors: [NSSortDescriptor]?) -> [CdFolder]?

    /**
     - Returns: The folder of the given type, if any.
     */
    func folderByType(_ type: FolderType, email: String) -> CdFolder?

    /**
     - Returns: The folder of the given type, if any.
     */
    func folderByType(_ type: FolderType, account: CdAccount) -> CdFolder?

    func accountByEmail(_ email: String) -> CdAccount?
    func accountsByPredicate(_ predicate: NSPredicate?,
                             sortDescriptors: [NSSortDescriptor]?) -> [CdAccount]?
    func setAccountAsLastUsed(_ account: CdAccount) -> CdAccount
    func fetchLastAccount() -> CdAccount?
    
    func insertAccountFromEmailConnectInfo(_ connectInfo: EmailConnectInfo) -> CdAccount
    func insertNewMessage() -> CdMessage

    /**
     Creates new message for sending, with the correct from and folder setup.
     */
    func insertNewMessageForSendingFromAccountEmail(_ email: String) -> CdMessage?

    func insertAttachmentWithContentType(
        _ contentType: String?, filename: String?, data: Data) -> CdAttachment

    func insertOrUpdateContactEmail(_ email: String, name: String?) -> CdIdentity
    func insertOrUpdateContactEmail(_ email: String) -> CdIdentity

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
                                  accountEmail: String) -> CdFolder?

    func insertOrUpdateMessageReference(_ messageID: String) -> CdMessageReference
    func insertMessageReference(_ messageID: String) -> CdMessageReference

    /**
     - Returns: List of contact that match the given snippet (either in the name, or email).
     */
    func contactsBySnippet(_ snippet: String) -> [CdIdentity]

    func save()

    /**
     For debugging: Dumps some important DB contents.
     */
    func dumpDB()

    /**
     Deletes the given mail from the store.
     */
    func deleteMail(_ message: CdMessage)

    /**
     Deletes the given attachment from the store.
     */
    func deleteAttachment(_ attachment: CdAttachment)

    /**
     Deletes all attachments from the given mail.
     */
    func deleteAttachmentsFromMessage(_ message: CdMessage)

    /**
     - Returns: true if there are no accounts yet.
     */
    func accountsIsEmpty() -> Bool
}

/**
 Core data model implementation
 */
open class CdModel: ICdModel {

    let comp = "CdModel"

    open static let CouldNotCreateFolder = 1000

    open let context: NSManagedObjectContext

    public init(context: NSManagedObjectContext) {
        self.context = context
    }

    func singleEntityWithName(_ name: String, predicate: NSPredicate? = nil,
                              sortDescriptors: [NSSortDescriptor]? = nil) -> NSManagedObject? {
        let fetch = NSFetchRequest<NSManagedObject>.init(entityName: name)
        fetch.predicate = predicate
        fetch.sortDescriptors = sortDescriptors
        do {
            let objs = try context.fetch(fetch)
            if objs.count == 1 {
                return objs[0]
            } else if objs.count == 0 {
                return nil
            } else {
                Log.warn(component: comp, "Several objects (\(name)) found for predicate: \(predicate)")
                return objs[0]
            }
        } catch let err as NSError {
            Log.error(component: comp, error: err)
        }
        return nil
    }

    open func entitiesWithName(
        _ name: String, predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor]? = nil)
        -> [NSManagedObject]?
    {
        let fetch = NSFetchRequest<NSManagedObject>.init(entityName: name)
        fetch.predicate = predicate
        fetch.sortDescriptors = sortDescriptors
        do {
            let objs = try context.fetch(fetch)
            return objs
        } catch let err as NSError {
            Log.error(component: comp, error: err)
        }
        return nil
    }

    open func countWithName(_ name: String,
                              predicate: NSPredicate? = nil) -> Int {
        let fetch = NSFetchRequest<NSManagedObject>.init(entityName: name)
        fetch.predicate = predicate
        do {
            let number = try context.count(for: fetch)
            if number != NSNotFound {
                return number
            }
        } catch let error as NSError {
            Log.error(component: comp, error: error)
        }
        return 0
    }

    open func contactByEmail(_ email: String) -> CdIdentity? {
        if let contacts = contactsByPredicate(NSPredicate.init(format: "email = %@", email), sortDescriptors: nil) {
            if contacts.count == 1 {
                return contacts[0]
            } else if contacts.count == 0 {
                return nil
            } else {
                Log.warn(component: comp, "Several contacts found for email: \(email)")
                return contacts[0]
            }
        }
        return nil
    }

    open func contactsByPredicate(_ predicate: NSPredicate?,
                                    sortDescriptors: [NSSortDescriptor]?) -> [CdIdentity]? {
        // XXX: Instead of just "CdIdentity" a method on the contact would be required.
        return entitiesWithName("CdIdentity", predicate: predicate,
            sortDescriptors: sortDescriptors)?.map() {$0 as! CdIdentity}
    }

    open func existingMessage(_ msg: CWIMAPMessage) -> CdMessage? {
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
        if let mail = singleEntityWithName(CdMessage.entityName, predicate: pred) {
            let result = mail as! CdMessage
            return result
        }
        return nil
    }

    func newAccountFromImapSmtpConnectInfo(_ connectInfo: EmailConnectInfo) -> CdAccount {
        let account = NSEntityDescription.insertNewObject(
            forEntityName: CdAccount.entityName, into: context) as! CdAccount
        account.connectInfo.userName = connectInfo.userName
        
        // IMAP
        if (connectInfo.emailProtocol?.rawValue.isEqual(EmailProtocol.imap.rawValue))! {
            account.connectInfo.userName = connectInfo.userName
            account.connectInfo.loginName = connectInfo.loginName
            account.connectInfo.loginPassword = connectInfo.loginPassword
            account.connectInfo.networkAddress = connectInfo.networkAddress
            account.connectInfo.networkPort = connectInfo.networkPort
            account.connectInfo.connectionTransport = connectInfo.connectionTransport
        }
        // SMTP
        else {
            account.connectInfo.userName = connectInfo.userName
            account.connectInfo.loginName = connectInfo.loginName
            account.connectInfo.loginPassword = connectInfo.loginPassword
            account.connectInfo.networkAddress = connectInfo.networkAddress
            account.connectInfo.networkPort = connectInfo.networkPort
            account.connectInfo.connectionTransport = connectInfo.connectionTransport
        }

        return account
    }

    open func insertAccountFromEmailConnectInfo(_ connectInfo: EmailConnectInfo) -> CdAccount {
        if let ac = accountByEmail(connectInfo.userName) {
            return ac
        }

        let account = newAccountFromImapSmtpConnectInfo(connectInfo)
        save()
        // An SMTP and IMAP account are considered seperate.
        let _ = KeyChain.add(key: connectInfo.userName,
                             serverType: (connectInfo.emailProtocol?.rawValue)!,
                             password: connectInfo.loginPassword)
        return account
    }

    open func insertNewMessage() -> CdMessage {
        let mail = NSEntityDescription.insertNewObject(
            forEntityName: CdMessage.entityName, into: context) as! CdMessage
        return mail
    }

    open func insertNewMessageForSendingFromAccountEmail(_ email: String) -> CdMessage? {
        guard let account = accountByEmail(email) else {
            Log.warn(component: comp, "No account with email found: \(email)")
            return nil
        }
        let message = insertNewMessage()
        let contact = insertOrUpdateContactEmail(account.connectInfo.userName)
        message.from = contact
        guard let folder = folderByType(FolderType.localOutbox, email: account.connectInfo.userName) else {
            Log.warn(component: comp, "Expected outbox folder to exist")
            return nil
        }
        message.parent = folder
        return message
    }

    open func insertAttachmentWithContentType(
        _ contentType: String?, filename: String?, data: Data) -> CdAttachment {
        
        // XXX: CdAttachment needs an entity name (like before) as to avoid explicit strings.
        let attachment = NSEntityDescription.insertNewObject(
            forEntityName: "Attachment", into: context) as! CdAttachment
        attachment.mimeType = contentType
        attachment.fileName = filename
        attachment.size = Int64(data.count)
        attachment.data = data as NSData?
        return attachment
    }

    open func setAccountAsLastUsed(_ account: CdAccount) -> CdAccount {
        UserDefaults.standard.set(
            account.connectInfo.userName, forKey: Constants.kSettingLastAccountEmail)
        UserDefaults.standard.synchronize()
        return account
    }

    open func fetchLastAccount() -> CdAccount? {
        let lastEmail = UserDefaults.standard.string(
            forKey: Constants.kSettingLastAccountEmail)

        var predicate = NSPredicate.init(value: true)

        if lastEmail?.characters.count > 0 {
            predicate = NSPredicate.init(format: "email == %@", lastEmail!)
        }

        if let account = singleEntityWithName(CdAccount.entityName, predicate: predicate) {
            return setAccountAsLastUsed(account as! CdAccount)
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

    open func accountByEmail(_ email: String) -> CdAccount? {
        let predicate = NSPredicate.init(format: "email = %@", email)
        return singleEntityWithName(CdAccount.entityName, predicate: predicate)
            as? CdAccount
    }

    open func accountsByPredicate(_ predicate: NSPredicate? = nil,
                                    sortDescriptors: [NSSortDescriptor]? = nil) -> [CdAccount]? {
        return entitiesWithName(CdAccount.entityName, predicate: predicate,
            sortDescriptors: sortDescriptors)?.map() {$0 as! CdAccount}
    }

    open func save() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                Log.error(component: comp, error: nserror)
                abort()
            }
        }
    }

    func folderPredicateByName(_ name: String, email: String) -> NSPredicate {
        return NSPredicate.init(format: "account.email = %@ and name = %@", email, name)
    }

    func insertFolderName(_ name: String, account: CdAccount) -> CdFolder {
        if let folder = folderByName(name, email: account.connectInfo.userName) {
            // reactivate folder if previously deleted

            return folder
        }

        let folder = NSEntityDescription.insertNewObject(
            forEntityName: CdFolder.entityName, into: context) as! CdFolder

        folder.name = name
        /* folder.account is optional
        folder.account = account
        */

        if name.uppercased() == ImapSync.defaultImapInboxName.uppercased() {
        } else {
            for ty in FolderType.allValuesToCheckFromServer {
                var foundMatch = false
                for theName in ty.folderNames() {
                    if name.matchesPattern("\(theName)",
                                           reOptions: [.caseInsensitive]) {
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

    func reactivateFolder(_ folder: CdFolder) -> CdFolder {
        return folder
    }

    open func insertOrUpdateFolderName(_ folderName: String, folderSeparator: String?,
                                         accountEmail: String) -> CdFolder? {
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
                // Create folder hierarchy if necessary
                var pathsSoFar = [String]()
                var parentFolder: CdFolder? = nil
                let paths = folderName.components(separatedBy: separator)
                for p in paths {
                    pathsSoFar.append(p)
                    let pathName = (pathsSoFar as NSArray).componentsJoined(
                        by: separator)
                    let folder = insertFolderName(pathName, account: account)
                    folder.parent = parentFolder
                    if let pf = parentFolder {
                        pf.addToSubFolders(folder)
                    }
                    parentFolder = folder
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
                                   sortDescriptors: [NSSortDescriptor]? = nil) -> CdMessage? {
        return singleEntityWithName(CdMessage.entityName, predicate: predicate,
                                    sortDescriptors: sortDescriptors) as? CdMessage
    }

    open func messagesByPredicate(_ predicate: NSPredicate? = nil,
                                    sortDescriptors: [NSSortDescriptor]? = nil) -> [CdMessage]? {
        return entitiesWithName(CdMessage.entityName, predicate: predicate,
            sortDescriptors: sortDescriptors)?.map() {$0 as! CdMessage}
    }

    open func messageCountByPredicate(_ predicate: NSPredicate? = nil) -> Int {
        return countWithName(CdMessage.entityName, predicate: predicate)
    }

    open func messageByUID(_ uid: Int, folderName: String) -> CdMessage? {
        return messageByPredicate(NSPredicate.init(format: "uid = %d", uid))
    }

    open func messageByMessageID(_ messageID: String) -> CdMessage? {
        let predicate = NSPredicate.init(format: "messageID = %@", messageID)
        return messageByPredicate(predicate, sortDescriptors: nil)
    }

    open func lastUidInFolderNamed(_ folderName: String) -> UInt {
        let fetch = NSFetchRequest<NSManagedObject>.init(entityName: CdMessage.entityName)
        fetch.predicate = NSPredicate.init(format: "folder.name = %@", folderName)
        fetch.fetchLimit = 1
        fetch.sortDescriptors = [NSSortDescriptor.init(key: "uid", ascending: false)]
        do {
            let elems = try context.fetch(fetch)
            if elems.count > 0 {
                if elems.count > 1 {
                    Log.warn(component: comp, "lastUID has found more than one element")
                }
                if let msg = elems[0] as? CdMessage {
                    return UInt(msg.uid)
                } else {
                    Log.warn(component: comp, "Could not cast core data result to Message")
                }
            } else if elems.count > 0 {
                Log.warn(component: comp, "lastUID has several objects with the same UID?")
            }
        } catch let error as NSError {
            Log.error(component: comp, error: error)
        }
        Log.warn(component: comp, "lastUID no object found, returning 0")
        return 0
    }

    open func folderCountByPredicate(_ predicate: NSPredicate? = nil) -> Int {
        return countWithName(CdFolder.entityName, predicate: predicate)
    }

    open func foldersByPredicate(_ predicate: NSPredicate? = nil,
                                   sortDescriptors: [NSSortDescriptor]? = nil) -> [CdFolder]? {
        return entitiesWithName(CdFolder.entityName, predicate: predicate,
            sortDescriptors: sortDescriptors)?.map() {$0 as! CdFolder}
    }

    open func folderByPredicate(_ predicate: NSPredicate? = nil,
                                  sortDescriptors: [NSSortDescriptor]? = nil) -> CdFolder? {
        return singleEntityWithName(CdFolder.entityName, predicate: predicate,
                                    sortDescriptors: sortDescriptors) as? CdFolder
    }

    open func folderByName(_ name: String, email: String) -> CdFolder? {
        return folderByPredicate(folderPredicateByName(name, email: email))
    }

    open func folderByName(
        _ name: String, email: String, folderType: Server.ServerType) -> CdFolder? {
        let p1 = folderPredicateByName(name, email: email)
        let p2 = NSPredicate.init(format: "folderType = %d", folderType.rawValue)
        let p3 = NSPredicate.init(format: "shouldDelete == false")
        let p = NSCompoundPredicate.init(andPredicateWithSubpredicates: [p1, p2, p3])
        return folderByPredicate(p)
    }

    open func anyFolderByName(_ name: String, email: String) -> CdFolder? {
        let p1 = folderPredicateByName(name, email: email)
        return folderByPredicate(p1)
    }

    open func foldersForAccountEmail(_ accountEmail: String, predicate: NSPredicate?,
                                       sortDescriptors: [NSSortDescriptor]?) -> [CdFolder]? {
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

    open func folderByType(_ type: FolderType, email: String) -> CdFolder? {
        let p1 = NSPredicate.init(format: "account.email == %@", email)
        let p2 = NSPredicate.init(format: "folderType == %d", type.rawValue)
        let p3 = NSPredicate.init(format: "shouldDelete == false")
        let p = NSCompoundPredicate.init(andPredicateWithSubpredicates: [p1, p2, p3])
        return singleEntityWithName(CdFolder.entityName, predicate: p) as? CdFolder
    }

    open func folderByType(_ type: FolderType, account: CdAccount) -> CdFolder? {
        return folderByType(type, email: account.connectInfo.userName)
    }

    open func insertOrUpdateContactEmail(_ email: String, name: String?) -> CdIdentity {
        // XXX: entityName should be gotten by method.
        let fetch = NSFetchRequest<NSManagedObject>.init(entityName: "CdIdentity")
        fetch.predicate = NSPredicate.init(format: "email == %@", email)
        do {
            var existing = try context.fetch(fetch) as! [CdIdentity]
            if existing.count > 1 {
                Log.warn(component: comp, "Duplicate contacts with address \(email)")
                existing[0].userName = name
                return existing[0]
            } else if existing.count == 1 {
                existing[0].userName = name
                return existing[0]
            }
        } catch let err as NSError {
            Log.error(component: comp, error: err)
        }
        let contact = NSEntityDescription.insertNewObject(
            // XXX: entityName should be gotten by method.
            forEntityName: "CdIdentity", into: context) as! CdIdentity
        contact.address = email
        contact.userName = name
        return contact
    }

    open func insertOrUpdateContactEmail(_ email: String) -> CdIdentity {
        return insertOrUpdateContactEmail(email, name: nil)
    }

    open func insertOrUpdateMessageReference(_ messageID: String) -> CdMessageReference {
        let p = NSPredicate.init(format: "messageID = %@", messageID)
        // XXX: Explicit string used for now (refactoring).
        if let ent = singleEntityWithName("CdMessageReference", predicate: p) {
            return ent as! CdMessageReference
        } else {
            return insertMessageReference(messageID)
        }
    }

    open func insertMessageReference(_ messageID: String) -> CdMessageReference {
        let ref = NSEntityDescription.insertNewObject(
            // XXX: Explicit string used for now (refactoring).
            forEntityName: "CdMessageReference", into: context) as! CdMessageReference
        ref.reference = messageID
        /* XXX: Don't save message into CdMessageReference type for now, as this breaks.
        if let msg = messageByMessageID(messageID) {
            ref.message = msg
        }
         */
        return ref
    }

    open func addContacts(_ contacts: [CWInternetAddress]) -> [String: CdIdentity] {
        var added: [String: CdIdentity] = [:]
        for address in contacts {
            let addr = insertOrUpdateContactEmail(address.address(),
                                                  name: address.personal())
            added[address.address()] = addr
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
    func addAttachmentsFromPantomimePart(_ part: CWPart, targetMail: CdMessage, level: Int) {
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
                targetMail.addAttachment(attachment)
            }
        }

        if let multiPart = content as? CWMIMEMultipart {
            for i in 0..<multiPart.count() {
                let subPart = multiPart.part(at: UInt(i))
                addAttachmentsFromPantomimePart(subPart, targetMail: targetMail, level: level + 1)
            }
        }
    }

    open func contactsBySnippet(_ snippet: String) -> [CdIdentity] {
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
                Log.info(component: 
                    comp,
                    "Folder \(folder.name) \(folder.messages!.count) messages")
            }
        }

        if let messages = messagesByPredicate(NSPredicate.init(value: true)) {
            for msg in messages {
                Log.info(component:
                    comp,
                    "Message \(msg.uid) folder \(msg.parent!.name) folder.count \(msg.parent!.messages!.count)")
            }
        }
    }

    open func deleteMail(_ message: CdMessage) {
        context.delete(message)
    }

    open func deleteAttachment(_ attachment: CdAttachment) {
        context.delete(attachment)
    }

    open func deleteAttachmentsFromMessage(_ message: CdMessage) {
        for a in message.attachments! {
            context.delete(a as! CdAttachment)
        }
        message.attachments = NSOrderedSet()
    }
}
